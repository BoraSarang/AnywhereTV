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
| 🎯 타겟 | 어르신 포함 전 연령 — 크고 단순한 UI |
| 📱 플랫폼 | macOS · Android (iOS/iPad 준비 중) |
| 📡 소스 | 지상파·종편·케이블 공식 스트림 + 유튜브 라이브 |
| ⚡ 기술 | Flutter 3.44 · media_kit (libmpv) · InnerTube API |
| 🧰 부가 | ChannelManager — 채널 편집 전용 macOS 앱 |

---

## ✨ 핵심 기능

### 🎬 매끄러운 시청 경험
- **원터치 채널 전환** — 좌우 스와이프 / ◀ ▶ 버튼
- **자동 재생 복구** — 스트림 오류 시 3회 자동 재시도
- **마지막 시청 채널 복원** — 앱을 껐다 켜도 이어서 시청
- **화면 회전 잠금** — 가로 고정 토글 (상단 바)

### 📡 스마트 스트림 해석 (Resolvers)
| 리졸버 | 대상 | 방식 |
|--------|------|------|
| **InnerTube** | 유튜브 라이브 채널 | 공식 player API → HLS 변환 |
| **YouTube Handle** | `@채널명/live` | 라이브 페이지 → videoId 추출 → InnerTube |
| **KBS** | KBS1/2 | 랜딩 API → 스트림 URL |
| **MBC** | MBC | OnAir API (5개 후보 순회) |
| **SBS** | SBS | play-api → mediaurl 추출 |

- **데이터 절약 모드** — 360p / 480p / 720p 해상도 설정
- **자동 최저 해상도 선택** — 360p 우선, 네트워크 불안정 시에도 안정 재생

### 👵 어르신 친화
- 56pt+ 대형 버튼, 고대비 다크 테마
- 채널명 + 현재 프로그램명 오버레이 표시
- 메뉴 깊이 2단계 이하

### 🗂 채널 관리 (ChannelManager)
전용 macOS 편집기로 채널 목록을 **Gist 기반으로 직접 관리**할 수 있습니다.

- URL 붙여넣기 → **자동 해석** → **바로 테스트 재생** → 카테고리 지정 → 저장
- 카테고리 추가/이름 변경/삭제/순서 변경
- **버전 히스토리 자동 기록** — 무엇을 추가/삭제했는지 한눈에
- GitHub Gist에 저장 → 앱은 자동으로 최신 채널 목록 동기화

> 🎬 **데모 흐름**: `유튜브 채널 핸들 or HLS URL 붙여넣기` → `분석` → `테스트 플레이` → `저장` → `Gist 업로드` → `앱에서 바로 시청`

---

## 📦 설치

| 플랫폼 | 방법 |
|--------|------|
| 📱 **Android** | [최신 APK 다운로드](https://github.com/BoraSarang/AnywhereTV/releases/latest) → 알 수 없는 소스 허용 → 설치 |
| 💻 **macOS** | [최신 ZIP 다운로드](https://github.com/BoraSarang/AnywhereTV/releases/latest) → 압축 해제 → Apps로 이동 |
| 📺 **홈페이지** | [AnywhereTV 랜딩 페이지](https://borasarang.github.io/AnywhereTV/) |

```bash
# 개발자 모드 (macOS / Android)
./build_and_run.sh debug macos
./build_and_run.sh debug android
```

---

## 🏗 아키텍처

```
┌────────────────────────────────────────────────────────────┐
│                        AnywhereTV App                       │
│  ┌────────────┐  ┌───────────────┐  ┌───────────────────┐   │
│  │ ChannelList  │→│  PlayerScreen  │→│  DebugPanel (Debug)│   │
│  └──────┬─────┘  └───────┬───────┘  └───────────────────┘   │
│         │                │                                   │
│  ┌──────▼─────┐  ┌──────▼───────┐                            │
│  │ChannelRepo │  │HlsPlayerAdapter│  (media_kit + libmpv)     │
│  └──────┬─────┘  └──────┬───────┘                            │
│         │               │                                   │
│  Gist JSON ←─────────────┘                                   │
└─────────┼────────────────────────────────────────────────┘
          │
┌─────────▼────────────────┐   ┌─────────────────────────────┐
│      ChannelManager      │   │          Gist                │
│  (macOS 전용 편집기)      │   │      channels.json          │
│   URL → 테스트 → 저장     │──▶│   (버전+히스토리 포함)        │
└──────────────────────────┘   └─────────────────────────────┘
```

```
 
| 리포지토리 구성 |
```
📁 anywhere_tv/        — Android/macOS 앱 (Flutter)
📁 channel_manager/    — 채널 편집 전용 macOS 앱 (Flutter)
📁 docs/               — PRD · DESIGN · PLAN · TODO · 랜딩 페이지
📁 .github/workflows/  — CI/CD 자동 릴리스 (Android APK + macOS ZIP)
```

---

## 🧠 기술 스택

| 영역 | 기술 |
|------|------|
| 프레임워크 | Flutter 3.44 (stable) |
| 비디오 | media_kit / media_kit_video (libmpv MPV 엔진) |
| 유튜브 | InnerTube **androidSdkless** 클라이언트 직접 호출 |
| 채널 데이터 | GitHub Gist JSON (버전 + 변경 이력 포함) |
| 백그라운드 | flutter_background_service (Android foreground notification) |
| CI/CD | GitHub Actions — 태그 기반 자동 빌드 + Release |

---

## 📦 릴리스

모든 릴리스는 GitHub Actions가 자동 빌드합니다.

| 버전 | 내용 |
|------|------|
| **v1.2.1** | 자막 디버깅 완료 (burned-in 한계 문서화) · 안정화 |
| **v1.2.0** | EPG 프로그램명 표시 · 백그라운드 오디오 · 자동 재접속 · 채널 검색 |
| **v1.1.0** | DebugPanel · 빌드 디스패처 · 번들 ID 통일 |
| **v1.0.0** | Phase 1 MVP — 8개 채널 · 즐겨찾기 · 데이터 절약 모드 |

[전체 변경 이력](CHANGELOG.md)

---

## 🤝 기여 & 문의

- 프로젝트: [github.com/BoraSarang/AnywhereTV](https://github.com/BoraSarang/AnywhereTV)
- 문의: [이슈 등록](https://github.com/BoraSarang/AnywhereTV/issues) · leeborasarang@gmail.com

---

<div align="center">
  <sub>개인·가족용으로 제작되었습니다. 모든 스트림은 공식적으로 무료 제공하는 소스만 사용합니다.</sub>
</div>