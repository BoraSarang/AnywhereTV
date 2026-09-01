<div align="center">

# 📺 어디서나 TV — AnywhereTV

### 에어컨 튼 방에서도, 거실 TV 채널을 그대로.

**실시간 TV 스트리밍 앱** · macOS + Android · 무료 공식 스트림만 사용

[![Release](https://img.shields.io/github/v/release/BoraSarang/AnywhereTV?style=for-the-badge&color=6366f1)](https://github.com/BoraSarang/AnywhereTV/releases/latest)
[![Platform](https://img.shields.io/badge/플랫폼-macOS%20%7C%20Android-22c55e?style=for-the-badge)](#)
[![Framework](https://img.shields.io/badge/Flutter-3.44-02569B?style=for-the-badge&logo=flutter)](#)
[![License](https://img.shields.io/badge/license-개인용-fbbf24?style=for-the-badge)](#)

</div>

---

## 🚀 한눈에 보기

> **"거실에 있는 TV가 아니라, 내가 있는 곳이 거실이다."**

어디서나 TV(AnywhereTV)는 **무료 공식 스트림 + 유튜브 라이브**를 모아
어디서든 실시간 채널을 이어 보게 해주는 크로스플랫폼 스트리밍 앱입니다.

셋톱박스 · 홈서버 · PC 상시 가동이 전혀 필요 없습니다. 설치만 하면 끝.

| 파악 | 내용 |
|------|------|
| 🎯 타겟 | 어르신 포함 전 연령 — 크고 단순한 UI + TTS 음성 안내 |
| 📱 플랫폼 | macOS · Android (D-pad / PiP 지원) |
| 📡 소스 | 지상파·종편·케이블 공식 스트림 + 유튜브 라이브 + 라디오 |
| ⚡ 기술 | Flutter 3.44 · media_kit (libmpv) · InnerTube API |
| 🧰 부가 | ChannelManager — AI 기반 채널 편집 전용 macOS 앱 |
| ✍️ 브랜드 | `com.borasarang.*` · [GitHub](https://github.com/BoraSarang/AnywhereTV) |

---

## ✨ 핵심 기능

### 🎬 매끄러운 시청 경험
- **원터치 채널 전환** — 좌우 스와이프 / ◀ ▶ 버튼 / 채널 즉시 전환(스트림 캐시)
- **자동 재생 복구** — 스트림 오류 시 3회 자동 재시도 + **대체 URL 페일오버**(`backupStreamUrl`)
- **마지막 시청 채널 복원** · **시청 기록** · **즐겨찾기 드래그 재정렬**
- **백그라운드 재생** (Android foreground) · **PiP** · 화면 회전 잠금

### 📡 스마트 스트림 해석 (Resolvers)
| 리졸버 | 대상 | 방식 |
|--------|------|------|
| **InnerTube** | 유튜브 라이브 채널 | 공식 player API → HLS 변환 |
| **YouTube Handle** | `@채널명/live` | 라이브 페이지 → videoId 추출 → InnerTube |
| **KBS** | KBS1/2 | 랜딩 API → 스트림 URL |
| **MBC** | MBC | OnAir API (5개 후보 순회) |
| **SBS** | SBS | play-api → mediaurl 추출 |

- 소스 타입: **HLS / YouTube / dash / audio**
- **데이터 절약 모드** — 360p / 480p / 720p 해상도 설정, 자동 최저 해상도 선택

### 📺 EPG & 편성
- **현재 방영중 프로그램명** 표시 (채널 타일 + 플레이어 오버레이)
- **24시간 편성표 타임라인** · **방송 시작 알림** (EPG 연동)

### 👵 어르신 친화
- 56pt+ 대형 버튼, 고대비 다크 테마 + **TTS 음성 안내**
- 채널명 + 현재 프로그램명 오버레이 표시, 메뉴 깊이 2단계 이하

### 🗂 ChannelManager — AI 채널 편집기
전용 macOS 편집기로 채널 목록을 **Gist 기반으로 직접 관리**할 수 있습니다.

- **AI 채널 추천** — 자연어 검색("경제 뉴스 24시간 채널") + 사이트 URL 조사 (유튜브 폴백으로 무료 동작)
- **AI 로고/채널명 검색** — Gemini + 유튜브 검색 파싱으로 자동 제안
- **AI 어시스턴트** — 자연어 명령("KBS 뉴스 추가해줘") → 수정 JSON → Diff 미리보기 → 적용
- **스트림 헬스체크** — 실패 채널 감지 + 리포트 화면 + 라이브 대시보드(5분 자동 검사)
- **중복/무결성 검사** · **Undo/Redo + 자동 백업** · **플레이리스트 Diff** · **일괄 편집**
- **M3U 가져오기/내보내기** · 버전 히스토리 자동 기록 · Gist 업로드 → 앱 자동 동기화

> 🎬 **데모 흐름**: `유튜브 채널 핸들 or HLS URL 붙여넣기` → `AI/분석` → `테스트 재생` → `저장` → `Gist 업로드` → `앱에서 바로 시청`

---

## 📦 설치

| 플랫폼 | 방법 |
|--------|------|
| 📱 **Android** | [최신 APK 다운로드](https://github.com/BoraSarang/AnywhereTV/releases/latest) → 알 수 없는 소스 허용 → 설치 |
| 💻 **macOS** | [최신 ZIP 다운로드](https://github.com/BoraSarang/AnywhereTV/releases/latest) → 압축 해제 → Apps로 이동 |
| 🖥 **ChannelManager** | 같은 [Release](https://github.com/BoraSarang/AnywhereTV/releases/latest)에서 별도 다운로드 |
| 📺 **홈페이지** | [AnywhereTV 랜딩 페이지](https://borasarang.github.io/AnywhereTV/) |

```bash
# 개발자 모드 (macOS / Android / ChannelManager)
./build_and_run.sh debug macos
./build_and_run.sh debug android
./build_and_run.sh debug cm
```

---

## 🏗 아키텍처

```
┌────────────────────────────────────────────────────────────┐
│                     AnywhereTV App (macOS/Android)          │
│  ┌────────────┐  ┌───────────────┐  ┌───────────────────┐   │
│  │ ChannelList │→│  PlayerScreen  │→│  DebugPanel (Debug)│   │
│  └──────┬─────┘  └───────┬───────┘  └───────────────────┘   │
│         │                │                                   │
│  ┌──────▼─────┐ ┌───────▼───────┐  리졸버(packages/shared)    │
│  │ChannelRepo │ │HlsPlayerAdapter│  media_kit + libmpv       │
│  └──────┬─────┘ └───────┬───────┘                            │
│         │               │                                   │
│  Gist JSON ←─────────────┘                                   │
└─────────┼────────────────────────────────────────────────┘
          │
┌─────────▼────────────────┐   ┌─────────────────────────────┐
│     ChannelManager       │   │          Gist                │
│  (macOS 전용 편집기)      │   │      channels.json          │
│  URL→AI→테스트→저장       │──▶│   (버전+히스토리 포함)        │
└──────────────────────────┘   └─────────────────────────────┘
```

```
| 리포지토리 구성 |
📁 anywhere_tv/        — Android/macOS 앱 (Flutter)
📁 channel_manager/    — AI 채널 편집 전용 macOS 앱 (Flutter)
📁 packages/shared/    — 리졸버/로거 공유 패키지
📁 docs/               — PRD · DESIGN · PLAN · TODO · 랜딩 페이지
📁 .github/workflows/  — CI/CD (릴리스 · Pages · 리졸버 헬스체크)
```

---

## 🧠 기술 스택

| 영역 | 기술 |
|------|------|
| 프레임워크 | Flutter 3.44 (Dart 3.12) · 모노레포(pnpm-workspace) |
| 비디오 | media_kit / media_kit_video (libmpv MPV 엔진) |
| 유튜브 | InnerTube androidSdkless 클라이언트 직접 호출 |
| AI | Gemini HTTP — 채널 추천/로고 검색/어시스턴트 (유튜브 폴백 지원) |
| EPG/저장 | XMLTV(Drift SQLite 캐시) · Gist JSON · shared_preferences |
| 채널 데이터 | GitHub Gist JSON (버전 + 변경 이력 포함) |
| 백그라운드 | flutter_background_service (Android foreground) |
| CI/CD | GitHub Actions — 태그 기반 자동 빌드 + Release · Pages · 헬스체크 cron |

---

## 📦 릴리스

모든 릴리스는 GitHub Actions가 자동 빌드합니다.

| 버전 | 내용 |
|------|------|
| **v2.4.0** | AI 로고/채널명 검색 · AI 채널 추천(자연어/URL) · 소스 타입 dash/audio · 브랜드 교체 · macOS 디자인 표준 |
| **v2.3.0** | ChannelManager 고도화 — 헬스체크·검증·Undo백업·일괄편집·로고·Diff·M3U·AI어시스턴트·대체URL |
| **v2.0.x** | 한국 EPG · 편성표 · SQLite · 채널 확장 · PiP · TTS · 방송 알림 |
| **v1.2.x** | EPG · 백그라운드 · 자동 재연결 · 채널 검색 · 자막 디버깅 |

[전체 변경 이력](CHANGELOG.md) · [로드맵](docs/ROADMAP.md)

---

## 🤝 기여 & 문의

- 프로젝트: [github.com/BoraSarang/AnywhereTV](https://github.com/BoraSarang/AnywhereTV)
- 문의: [이슈 등록](https://github.com/BoraSarang/AnywhereTV/issues) · leeborasarang@gmail.com

---

<div align="center">
  <sub>개인·가족용으로 제작되었습니다. 모든 스트림은 공식적으로 무료 제공하는 소스만 사용합니다.</sub>
</div>
