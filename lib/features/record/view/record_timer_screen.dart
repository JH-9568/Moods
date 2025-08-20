// 타이머 + 무드/목표 입력 화면
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moods/features/record/controller/record_controller.dart';
import 'package:moods/features/record/widget/widget.dart';

class RecordTimerScreen extends ConsumerStatefulWidget {
  final StartArgs startArgs; // 라우트 진입 시 전달
  const RecordTimerScreen({super.key, required this.startArgs});

  @override
  ConsumerState<RecordTimerScreen> createState() => _RecordTimerScreenState();
}

class _RecordTimerScreenState extends ConsumerState<RecordTimerScreen> {
  late final DraggableScrollableController _dragCtrl;

  @override
  void initState() {
    super.initState();
    _dragCtrl = DraggableScrollableController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(recordControllerProvider.notifier).startWithArgs(widget.startArgs);
    });
  }

  @override
  void dispose() {
    _dragCtrl.dispose();
    super.dispose();
  }

  String _fmt(Duration d) {
    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  Future<bool> _onWillPop() async {
    final st = ref.read(recordControllerProvider);
    if (!st.dirty) return true;

    if (st.selectedMood.isEmpty) {
      await showDialog(context: context, builder: (_) => const AlertDialogBasic(title: '잠시만요!', message: '공간 무드를 선택해주세요', okText: '확인'));
      return false;
    }

    final yes = await showDialog<bool>(
      context: context,
      builder: (_) => const ConfirmDialog(
        title: '지금 나가면 기록이 저장되지 않아요',
        okText: '네\n기록을 저장할래요',
        cancelText: '아니요\n나중에요',
      ),
    );
    if (yes == true) {
      await ref.read(recordControllerProvider.notifier).finish();
      await ref.read(recordControllerProvider.notifier).exportToRecord();
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final st = ref.watch(recordControllerProvider);
    final ctrl = ref.read(recordControllerProvider.notifier);

    final timerCard = TimerCard(
      elapsedText: _fmt(st.elapsed),
      isRunning: st.isRunning,
      wallpaperUrl: st.wallpaperUrl,
      onToggleRun: () async => st.isRunning ? await ctrl.pause() : await ctrl.resume(),
      onClose: () async {
        if (st.selectedMood.isEmpty) {
          await showDialog(context: context, builder: (_) => const AlertDialogBasic(title: '잠시만요!', message: '공간 무드를 선택해주세요', okText: '확인'));
          return;
        }
        final yes = await showDialog<bool>(
          context: context,
          builder: (_) => const ConfirmDialog(title: '공부를 끝내시겠어요?', okText: '네\n기록을 저장할래요', cancelText: '아니요\n이어서 할게요'),
        );
        if (yes == true) {
          await ctrl.finish();
          await ctrl.exportToRecord();
          if (mounted) Navigator.of(context).pop();
        }
      },
    );

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                flex: 4,
                child: DraggableScrollableSheet(
                  controller: _dragCtrl,
                  initialChildSize: 0.42,
                  minChildSize: 0.42,
                  maxChildSize: 1.0,
                  builder: (_, scroll) => SingleChildScrollView(controller: scroll, child: timerCard),
                ),
              ),
              Expanded(
                flex: 6,
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  children: [
                    const SizedBox(height: 8),
                    const Text('공간 무드', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _moodTags.map((m) {
                        final on = st.selectedMood == m;
                        return ChoiceChip(label: Text(m), selected: on, onSelected: (_) => ctrl.selectMood(m));
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                    const Text('오늘 목표', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    ...st.goals.asMap().entries.map((e) {
                      final i = e.key;
                      final g = e.value;
                      return ListTile(
                        leading: Checkbox(value: g.done, onChanged: (v) => ctrl.toggleGoal(i, v ?? false)),
                        title: Text(g.text),
                        dense: true,
                      );
                    }),
                    const SizedBox(height: 120),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

const List<String> _moodTags = [
  '트렌디한', '감성적인', '개방적인', '자연 친화적인', '컨셉 있는', '활기찬', '아늑한', '조용한'
];
