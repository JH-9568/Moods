# Moods

**공부 시간만 기록하지 말고, 몰입했던 공간도 함께.**

어디서 어떤 기분으로 공부했는지 기록하고, 나에게 맞는 공부 공간을 돌아보는 모바일 앱입니다. **2025 예술적인 소프트웨어 대회**에 출품한 팀 프로젝트입니다.

[프로젝트 소개](https://jinhyeong-studio.jinhyeong9568-663.workers.dev/projects/moods) · [발표 자료](https://github.com/user-attachments/files/23470223/ppt.pdf)

## 주요 기능

| 흐름 | 경험 |
| --- | --- |
| 공부 시작 | 무드 화면과 타이머로 집중 시간 기록 |
| 기록 남기기 | 장소·감정·공간 태그·사진을 함께 저장 |
| 돌아보기 | 캘린더에서 일별 기록 확인 |
| 공간 발견 | 공부 시간·횟수와 공간별 통계·랭킹 확인 |
| 성장 확인 | 기록을 쌓으며 마이페이지 캐릭터의 변화 확인 |

정량적인 공부 시간과 정성적인 공간·감정 기록을 함께 다룹니다. 공간 추천은 기록과 조건에 기반하며, 학습된 추천 모델의 성능을 주장하지 않습니다.

## 기술

**Flutter · Dart · Riverpod · go_router · Supabase**

이 저장소는 모바일 클라이언트입니다. 인증, 공부 세션, 기록·사진, 홈·통계 API와 연결합니다.

## 실행

```bash
flutter pub get
# docs/env_and_secrets.md를 참고해 .env 설정
flutter run
```

API 주소, Supabase 공개 클라이언트 설정, 지도·카카오 설정이 필요합니다. 비밀 키와 실제 환경 파일은 커밋하지 않습니다.

[환경 변수·시크릿 관리](docs/env_and_secrets.md)

## 팀과 역할

| 팀원 | 담당 |
| --- | --- |
| **정진형** | 프론트엔드·기획·레이아웃, 인증·기록·사진·세션 UI/API 연동 |
| 유현민 | 프론트엔드, 홈·마이페이지·통계 UI/API 연동 |
| 정대균 | 백엔드, 공부 기록·통계·사진 DB |
| 김회광 | 백엔드, 인증·회원·공간·피드백 DB |
| 최윤아 | 디자인, 기획·레이아웃·UI/UX |

<details>
<summary>대회 출품 판넬</summary>

<img src="https://github.com/user-attachments/assets/d05e29c0-96ca-42e2-8a4f-cf2312c6a453" alt="Moods 예술적인 소프트웨어 2025 출품 판넬 — 공부 공간·감정 기록과 앱 화면" width="880" />

</details>
