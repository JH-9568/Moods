// lib/features/record/view/map_view.dart
import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:moods/common/constants/api_constants.dart'; // baseUrl

/// Places / Geocoding API Key (빌드시 --dart-define 권장)
const MAPS_API_KEY = String.fromEnvironment(
  'MAPS_API_KEY',
  // TODO: 배포 전 교체/제한
  defaultValue: 'AIzaSyCmyiqBywUn5lrt-6AXya4Xy38W4tJ9UQk',
);

class SelectedPlace {
  final String name;     // 화면 표시용 이름
  final String placeId;  // 서버로 보낼 space_id (ChIJ…)
  final double lat;
  final double lng;
  final String address;
  const SelectedPlace({
    required this.name,
    required this.placeId,
    required this.lat,
    required this.lng,
    required this.address,
  });
}

class MapSelectPage extends StatefulWidget {
  const MapSelectPage({super.key});
  @override
  State<MapSelectPage> createState() => _MapSelectPageState();
}

class _MapSelectPageState extends State<MapSelectPage> {
  GoogleMapController? _map;
  LatLng? _center;
  String _humanAddress = '';
  bool _loading = true;

  final _searchCtrl = TextEditingController();
  final _searchFocus = FocusNode();
  Timer? _debounce;

  final _markers = <MarkerId, Marker>{};

  // 서버(우선) + 구글(대체)
  List<_ServerPlace> _serverResults = [];
  List<_Place> _googleResults = [];

  // 주소 캐시(서버 결과 보강용)
  final Map<String, String> _addrCache = {};
  final Set<String> _addrFetching = {};

  // 자동완성 제안
  List<_AutocompleteItem> _suggestions = [];

  static const _fallbackSeoul = LatLng(37.5662952, 126.9779451);

  @override
  void initState() {
    super.initState();
    _bootstrap();

    _searchCtrl.addListener(() {
      final q = _searchCtrl.text.trim();
      _debounce?.cancel();
      _debounce = Timer(const Duration(milliseconds: 220), () {
        if (q.isEmpty || !_searchFocus.hasFocus) {
          if (_suggestions.isNotEmpty) setState(() => _suggestions = []);
        } else {
          _fetchAutocomplete(q);
        }
      });
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _center = _fallbackSeoul;
        _humanAddress = '서울특별시 중구';
      } else {
        var perm = await Geolocator.checkPermission();
        if (perm == LocationPermission.denied ||
            perm == LocationPermission.deniedForever) {
          perm = await Geolocator.requestPermission();
        }
        final p = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.best,
        );
        _center = LatLng(p.latitude, p.longitude);
        _humanAddress = await _reverseGeocode(_center!);
      }

      if (mounted) setState(() {});
      await Future.wait([
        _loadNearbyMarkers(_center ?? _fallbackSeoul),     // 지도 마커(구글)
        _loadNearbyFromServer(_center ?? _fallbackSeoul),  // 하단 리스트(서버)
      ]);

      if (_map != null && _center != null) {
        await _map!.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(target: _center!, zoom: 16),
          ),
        );
      }
    } catch (_) {
      _center ??= _fallbackSeoul;
      _humanAddress = '서울특별시 중구';
      await Future.wait([
        _loadNearbyMarkers(_center!),
        _loadNearbyFromServer(_center!),
      ]);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// ─────────────────────────────────────────────────────────
  /// 1) 하단 리스트: 우리 백엔드 /spaces/near (distance 포함)
  Future<void> _loadNearbyFromServer(LatLng center) async {
    final lat = center.latitude.toString();
    final lng = center.longitude.toString();

    // 동일 키 반복(type) 수동 작성
    final types = ['cafe', 'library', 'book_store', 'university'];
    final buf = StringBuffer('lat=$lat&lng=$lng&rad=800');
    for (final t in types) {
      buf.write('&type=$t');
    }
    final uri = Uri.parse('$baseUrl/spaces/near?${buf.toString()}');

    try {
      final res = await http.get(uri);
      if (res.statusCode ~/ 100 == 2) {
        final m = jsonDecode(res.body) as Map<String, dynamic>;
        final list = (m['places'] as List? ?? [])
            .map((e) => _ServerPlace.fromJson(e as Map<String, dynamic>))
            .toList()
          ..sort((a, b) => a.distance.compareTo(b.distance));
        if (mounted) setState(() => _serverResults = list);
      } else {
        if (mounted) setState(() => _serverResults = []);
      }
    } catch (_) {
      if (mounted) setState(() => _serverResults = []);
    }
  }

  /// 2) Google Places Details (주소/좌표 확정)
  Future<_SelectedLike> _fetchDetailsFor(
    String placeId, {
    String? nameFallback,
  }) async {
    try {
      final uri = Uri.parse('https://places.googleapis.com/v1/places/$placeId');
      final r = await http.get(uri, headers: {
        'X-Goog-Api-Key': MAPS_API_KEY,
        'X-Goog-FieldMask': 'id,displayName,formattedAddress,location',
      });

      if (r.statusCode ~/ 100 == 2) {
        final m = jsonDecode(r.body) as Map<String, dynamic>;
        final name = (m['displayName']?['text'] ?? nameFallback ?? '').toString();
        final addr = (m['formattedAddress'] ?? '').toString();
        final lat  = (m['location']?['latitude'] ?? 0).toDouble();
        final lng  = (m['location']?['longitude'] ?? 0).toDouble();

        return _SelectedLike(
          name: name,
          placeId: placeId,
          address: addr,
          lat: lat,
          lng: lng,
        );
      }
    } catch (_) {
      // ignore
    }

    // 실패 시 지도 중심값으로 보정해서 반환
    final c = _center ?? _fallbackSeoul;
    return _SelectedLike(
      name: nameFallback ?? '선택한 장소',
      placeId: placeId,
      address: '',
      lat: c.latitude,
      lng: c.longitude,
    );
  }

  /// 3) 지도 마커: Google Places Nearby (시각화용)
  Future<void> _loadNearbyMarkers(LatLng center) async {
    final uri = Uri.parse('https://places.googleapis.com/v1/places:searchNearby');
    final body = {
      "includedTypes": ["cafe", "library", "university", "book_store"],
      "maxResultCount": 15,
      "languageCode": "ko",
      "locationRestriction": {
        "circle": {
          "center": {"latitude": center.latitude, "longitude": center.longitude},
          "radius": 1200.0,
        }
      }
    };
    try {
      final res = await http.post(
        uri,
        headers: {
          "Content-Type": "application/json",
          "X-Goog-Api-Key": MAPS_API_KEY,
          "X-Goog-FieldMask":
              "places.id,places.displayName,places.formattedAddress,places.location",
        },
        body: jsonEncode(body),
      );
      if (res.statusCode ~/ 100 == 2) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final list = (data["places"] as List? ?? [])
            .map((e) => _Place.fromJson(e))
            .toList();

        final ms = <MarkerId, Marker>{};
        for (final p in list.take(15)) {
          final id = MarkerId(p.placeId);
          ms[id] = Marker(
            markerId: id,
            position: LatLng(p.lat, p.lng),
            infoWindow: InfoWindow(title: p.name, snippet: p.address),
            onTap: () => _select(_SelectedLike(
              name: p.name,
              placeId: p.placeId,
              lat: p.lat,
              lng: p.lng,
              address: p.address,
            )),
          );
        }
        if (mounted) {
          setState(() {
            _googleResults = list;
            _markers..clear()..addAll(ms);
          });
        }
      } else {
        if (mounted) setState(() => _googleResults = []);
      }
    } catch (_) {
      if (mounted) setState(() => _googleResults = []);
    }
  }

  /// 4) 검색 실행 (텍스트 검색)
  Future<void> _search(String q) async {
    if (q.trim().isEmpty || _center == null) return;
    _suggestions = [];
    setState(() {});
    final uri = Uri.parse('https://places.googleapis.com/v1/places:searchText');
    final body = {
      "textQuery": q.trim(),
      "languageCode": "ko",
      "maxResultCount": 20,
      "locationBias": {
        "circle": {
          "center": {"latitude": _center!.latitude, "longitude": _center!.longitude},
          "radius": 4000.0,
        }
      }
    };
    try {
      final res = await http.post(
        uri,
        headers: {
          "Content-Type": "application/json",
          "X-Goog-Api-Key": MAPS_API_KEY,
          "X-Goog-FieldMask":
              "places.id,places.displayName,places.formattedAddress,places.location",
        },
        body: jsonEncode(body),
      );
      if (res.statusCode ~/ 100 == 2) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final list = (data["places"] as List? ?? [])
            .map((e) => _Place.fromJson(e))
            .toList();

        // 마커 교체
        final ms = <MarkerId, Marker>{};
        for (final p in list.take(15)) {
          final id = MarkerId(p.placeId);
          ms[id] = Marker(
            markerId: id,
            position: LatLng(p.lat, p.lng),
            infoWindow: InfoWindow(title: p.name, snippet: p.address),
            onTap: () => _select(_SelectedLike(
              name: p.name, placeId: p.placeId, lat: p.lat, lng: p.lng, address: p.address)),
          );
        }
        if (mounted) {
          setState(() {
            _googleResults = list;
            _markers..clear()..addAll(ms);
          });
        }
        if (_map != null && list.isNotEmpty) {
          await _map!.animateCamera(
            CameraUpdate.newLatLngZoom(LatLng(list.first.lat, list.first.lng), 16),
          );
        }
      }
    } catch (_) {}
  }

  /// 4-1) 자동완성 제안
  Future<void> _fetchAutocomplete(String input) async {
    final c = _center ?? _fallbackSeoul;
    try {
      final uri = Uri.parse('https://places.googleapis.com/v1/places:autocomplete');
      final body = {
        "input": input,
        "languageCode": "ko",
        "locationBias": {
          "circle": {
            "center": {"latitude": c.latitude, "longitude": c.longitude},
            "radius": 5000.0
          }
        },
        "includeQueryPredictions": false
      };
      final r = await http.post(
        uri,
        headers: {
          "Content-Type": "application/json",
          "X-Goog-Api-Key": MAPS_API_KEY,
          // v1 필드마스크(예측 place 리소스와 표시 텍스트)
          "X-Goog-FieldMask": "predictions.placePrediction.place,predictions.text",
        },
        body: jsonEncode(body),
      );
      if (r.statusCode ~/ 100 == 2) {
        final m = jsonDecode(r.body) as Map<String, dynamic>;
        final preds = (m['predictions'] as List? ?? []);
        final items = <_AutocompleteItem>[];
        for (final e in preds) {
          final placePath = (e['placePrediction']?['place'] ?? '').toString(); // "places/ChIJ..."
          final id = placePath.split('/').last;
          final label = (e['text']?['text'] ?? '').toString();
          if (id.isNotEmpty && label.isNotEmpty) {
            items.add(_AutocompleteItem(placeId: id, label: label));
          }
        }
        if (mounted) setState(() => _suggestions = items.take(8).toList());
      } else {
        if (mounted) setState(() => _suggestions = []);
      }
    } catch (_) {
      if (mounted) setState(() => _suggestions = []);
    }
  }

  /// 5) 역지오코딩: 상단 “현위치: …”
  Future<String> _reverseGeocode(LatLng ll) async {
    final uri = Uri.parse(
      'https://maps.googleapis.com/maps/api/geocode/json'
      '?latlng=${ll.latitude},${ll.longitude}&language=ko&key=$MAPS_API_KEY',
    );
    try {
      final res = await http.get(uri);
      if (res.statusCode ~/ 100 == 2) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final results = (data['results'] as List? ?? []);
        if (results.isNotEmpty) {
          return (results.first['formatted_address'] ?? '').toString();
        }
      }
    } catch (_) {}
    return '';
  }

  /// 6) 상세(주소/좌표 보강) — 서버 리스트용(백엔드 row의 주소 채우기)
  Future<void> _ensureAddress(String spaceId, {String? fallbackName}) async {
    if (_addrCache.containsKey(spaceId) || _addrFetching.contains(spaceId)) return;
    _addrFetching.add(spaceId);
    try {
      final uri = Uri.parse('https://places.googleapis.com/v1/places/$spaceId');
      final r = await http.get(uri, headers: {
        "X-Goog-Api-Key": MAPS_API_KEY,
        "X-Goog-FieldMask": "id,displayName,formattedAddress,location",
      });
      if (r.statusCode ~/ 100 == 2) {
        final m = jsonDecode(r.body) as Map<String, dynamic>;
        _addrCache[spaceId] = (m['formattedAddress'] ?? '').toString();
      } else {
        _addrCache[spaceId] = '';
      }
    } catch (_) {
      _addrCache[spaceId] = '';
    } finally {
      _addrFetching.remove(spaceId);
      if (mounted) setState(() {});
    }
  }

  /// 7) 선택 완료
  Future<void> _select(_SelectedLike p) async {
    Navigator.pop(
      context,
      SelectedPlace(
        name: p.name,
        placeId: p.placeId,
        lat: p.lat,
        lng: p.lng,
        address: p.address,
      ),
    );
  }

  // 거리 포맷
  String _fmtDistance(double meters) {
    if (meters < 950) return '${meters.round()} m';
    final km = meters / 1000.0;
    return '${km.toStringAsFixed(km >= 10 ? 0 : 1)} km';
    // 999m -> 1.0 km 처럼 보이는 걸 방지하려 약간 보수적으로 컷
  }

  // 허버사인(지도 결과용 추정거리)
  double _haversine(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371000.0; // m
    final dLat = (lat2 - lat1) * math.pi / 180.0;
    final dLon = (lon2 - lon1) * math.pi / 180.0;
    final a = math.sin(dLat/2) * math.sin(dLat/2) +
        math.cos(lat1*math.pi/180.0) * math.cos(lat2*math.pi/180.0) *
        math.sin(dLon/2) * math.sin(dLon/2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1-a));
    return R * c;
  }

  @override
  Widget build(BuildContext context) {
    final center = _center ?? _fallbackSeoul;
    final showingServer = _serverResults.isNotEmpty;

    // AppBar 하단(검색/현위치)의 총 높이
    const double appBarBottomH = 96;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text(
          '지도에서 선택',
          style: TextStyle(fontWeight: FontWeight.w700, color: Colors.black),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(appBarBottomH),
          child: Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Column(
              children: [
                // 검색창
                TextField(
                  controller: _searchCtrl,
                  focusNode: _searchFocus,
                  textInputAction: TextInputAction.search,
                  onSubmitted: _search,
                  decoration: InputDecoration(
                    hintText: '검색하기',
                    prefixIcon: const Icon(Icons.search),
                    isDense: true,
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // 현위치 칩(작은 박스)
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFE5E7F4)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.location_on_outlined, size: 16, color: Colors.black54),
                          const SizedBox(width: 6),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 240),
                            child: Text(
                              '현위치: ${_humanAddress.isEmpty ? '확인 중…' : _humanAddress}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 12, color: Colors.black54),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () async {
                        setState(() => _loading = true);
                        await _bootstrap();
                      },
                      child: const Text('현위치', style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          // ── 지도
          GoogleMap(
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            mapToolbarEnabled: false,
            initialCameraPosition: CameraPosition(target: center, zoom: 15),
            onMapCreated: (c) => _map = c,
            markers: Set.of(_markers.values),
            onCameraIdle: () async {
              if (_map != null) {
                final pos = await _map!.getVisibleRegion();
                final mid = LatLng(
                  (pos.northeast.latitude + pos.southwest.latitude) / 2,
                  (pos.northeast.longitude + pos.southwest.longitude) / 2,
                );
                _center = mid;
                _loadNearbyFromServer(mid); // 드래그로 위치 바뀌면 서버 리스트 갱신
              }
            },
          ),

          // ── 자동완성 제안 오버레이(앱바 하단 바로 아래에 흰색 카드)
          if (_suggestions.isNotEmpty)
            Positioned(
              left: 16,
              right: 16,
              top: 0, // body의 top은 이미 AppBar+bottom 높이만큼 아래이므로 0이면 검색창 바로 밑
              child: Material(
                elevation: 6,
                borderRadius: BorderRadius.circular(10),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 280),
                  child: ListView.separated(
                    shrinkWrap: true,
                    padding: EdgeInsets.zero,
                    itemCount: _suggestions.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, i) {
                      final s = _suggestions[i];
                      return ListTile(
                        dense: true,
                        title: Text(s.label, maxLines: 1, overflow: TextOverflow.ellipsis),
                        onTap: () async {
                          _suggestions = [];
                          setState(() {});
                          // 선택 즉시 디테일 받아 pop
                          final d = await _fetchDetailsFor(s.placeId, nameFallback: s.label);
                          await _select(d);
                        },
                      );
                    },
                  ),
                ),
              ),
            ),

          // 로딩 바
          if (_loading)
            const Align(
              alignment: Alignment.topCenter,
              child: LinearProgressIndicator(minHeight: 2),
            ),

          // ── 하단 패널(더 많이 올라오게: max 0.88, 내부 스크롤 전환)
          DraggableScrollableSheet(
            initialChildSize: 0.26,
            minChildSize: 0.22,
            maxChildSize: 0.88, // 거의 맵을 덮고 아주 살짝만 남김
            builder: (context, scrollCtrl) {
              return Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                  boxShadow: [BoxShadow(blurRadius: 16, color: Color(0x33000000))],
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 8),
                    // 그립바
                    Container(
                      width: 44, height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0x22000000),
                        borderRadius: BorderRadius.circular(100),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: showingServer
                          ? ListView.separated(
                              controller: scrollCtrl,
                              itemCount: _serverResults.length,
                              separatorBuilder: (_, __) => const Divider(height: 1),
                              itemBuilder: (ctx, i) {
                                final p = _serverResults[i];
                                // 주소 보강 트리거 (1회)
                                _ensureAddress(p.spaceId, fallbackName: p.name);

                                final addr = _addrCache[p.spaceId] ?? '';
                                return ListTile(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                  leading: const Icon(Icons.place_outlined, size: 28),
                                  title: Text(
                                    p.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontWeight: FontWeight.w700),
                                  ),
                                  subtitle: Text(
                                    addr.isEmpty ? '주소 불러오는 중…' : addr,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 12, color: Colors.black45),
                                  ),
                                  trailing: Text(
                                    _fmtDistance(p.distance),
                                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                                  ),
                                  onTap: () async {
                                    // 상세로 좌표/주소 확정 후 pop
                                    final d = await _fetchDetailsFor(p.spaceId, nameFallback: p.name);
                                    await _select(d);
                                  },
                                );
                              },
                            )
                          : ListView.separated(
                              controller: scrollCtrl,
                              itemCount: _googleResults.length,
                              separatorBuilder: (_, __) => const Divider(height: 1),
                              itemBuilder: (ctx, i) {
                                final p = _googleResults[i];
                                final dist = (_center == null)
                                    ? null
                                    : _haversine(_center!.latitude, _center!.longitude, p.lat, p.lng);
                                return ListTile(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                  leading: const Icon(Icons.place_outlined, size: 28),
                                  title: Text(
                                    p.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontWeight: FontWeight.w700),
                                  ),
                                  subtitle: Text(
                                    p.address,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 12, color: Colors.black45),
                                  ),
                                  trailing: dist == null
                                      ? null
                                      : Text(
                                          _fmtDistance(dist),
                                          style: const TextStyle(fontSize: 12, color: Colors.black54),
                                        ),
                                  onTap: () => _select(_SelectedLike(
                                    name: p.name,
                                    placeId: p.placeId,
                                    lat: p.lat,
                                    lng: p.lng,
                                    address: p.address,
                                  )),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// ─── 내부 모델 ─────────────────────────────────────────────
class _Place {
  final String placeId; // "ChIJ..."
  final String name;
  final String address;
  final double lat;
  final double lng;

  _Place({
    required this.placeId,
    required this.name,
    required this.address,
    required this.lat,
    required this.lng,
  });

  factory _Place.fromJson(Map<String, dynamic> m) {
    final resourceName = (m['id'] ?? '').toString(); // e.g. "places/ChIJxxx"
    final placeId = resourceName.split('/').last;
    final name = (m['displayName']?['text'] ?? '').toString();
    final addr = (m['formattedAddress'] ?? '').toString();
    final lat = (m['location']?['latitude'] ?? 0).toDouble();
    final lng = (m['location']?['longitude'] ?? 0).toDouble();
    return _Place(placeId: placeId, name: name, address: addr, lat: lat, lng: lng);
  }
}

class _ServerPlace {
  final String spaceId;   // = Google Place ID
  final String name;
  final double distance;  // meters

  _ServerPlace({required this.spaceId, required this.name, required this.distance});

  factory _ServerPlace.fromJson(Map<String, dynamic> m) {
    return _ServerPlace(
      spaceId: (m['space_id'] ?? '').toString(),
      name: (m['name'] ?? '').toString(),
      distance: (m['distance'] is num)
          ? (m['distance'] as num).toDouble()
          : double.tryParse('${m['distance']}') ?? 0.0,
    );
  }
}

class _SelectedLike {
  final String name;
  final String placeId;
  final double lat;
  final double lng;
  final String address;
  _SelectedLike({
    required this.name,
    required this.placeId,
    required this.lat,
    required this.lng,
    required this.address,
  });
}

class _AutocompleteItem {
  final String placeId;
  final String label;
  _AutocompleteItem({required this.placeId, required this.label});
}
