# 변경 이력 (CHANGELOG)

## v1.2.0 (2026-07-30) — EPG + Background Audio + 안정화

### feat
- EPG: InnerTube `videoDetails.title` 추출 → PlayerScreen 오버레이에 프로그램명 표시
- EPG: `EpgService` — 채널별 현재/다음 프로그램 조회 지원
- StreamResolver가 `StreamResolutionResult` 반환 (url + title)
- Background Audio Service (Android foreground notification, 채널명 표시)
- Auto-reconnect: stream error 발생 시 3회 자동 재시도 (mpv seek 경고 필터링)
- 채널 검색: 채널 목록 화면에 검색 바 추가
- 화면 회전 버튼: 상단 바에서 가로모드 고정/해제

### fix
- macOS: `BackgroundAudioService.init()`가 Android/iOS 외 플랫폼에서 크래시 → platform 가드 추가
- Android: "Cannot seek in this stream" mpv 경고가 무한 재접속 루프 유발 → 필터 처리
- YouTube handle resolver: 리다이렉트 + HTML fallback 개선

### build
- `flutter_background_service` 의존성 추가
- media_kit_libs_android_video 의존성 추가
- main/AndroidManifest.xml INTERNET 권한 추가 (release APK)

## v1.1.0 (2026-07-28) — Debug Panel + 빌드 디스패처

### feat [macos]
- DebugLogger 전면 개편: platform 필드, maskSecrets, detectPlatform, formatForAgent
- DebugPanel v1.5/1.6 표준 준수: 🐛 아이콘, 320px 드래그 리사이즈, 자동 스크롤 1.5s 재개
- 플랫폼 필터 탭: [ALL] [MACOS] [IOS] [ANDROID] [WEB]
- Cmd+Shift+D 단축키 (Shortcuts + Intent 방식)
- release 빌드 시 DebugOverlay 완전 제거 (kReleaseMode)
- 번들 ID 통일: `com.okstart.anywheretv` (macOS/iOS/Android)
- 앱 샌드박스 entitlements 수정: 네트워크 클라이언트 권한 추가
- build_and_run.sh → v1.6 디스패처 패턴 (scripts/build-*.sh 분리)
- AGENTS.local.md 업데이트 (프로젝트별 설정/빌드 규칙)

### fix [macos]
- 기본 채널 순서 변경: EBS1→EBS2→연합뉴스TV→KBS1→... (재생 가능 채널 우선)
- 플레이어 에러 상태 UI 추가 (무한 스피너 → 경고 메시지 + 재시도 버튼)
- DebugOverlay: MaterialApp.builder 레벨로 이동 (GestureDetector 레이아웃 문제 회피)
- YTN 기본 즐겨찾기 제외 (youtubeVideoId null)

### docs
- PRD, DESIGN, PLAN, TODO, CHANGELOG 문서 작성

## v1.0.0 (2026-07-28) — Phase 1 MVP

### feat
- Flutter 프로젝트 생성 및 macOS/Android/iOS 타겟 설정
- Channel 모델 및 채널 리포지토리 (원격 JSON + 로컬 캐시 폴백)
- UserState 모델 및 SharedPreferences 기반 설정 저장
- media_kit 기반 HLS 스트림 재생 (EBS1, EBS2)
- youtube_player_flutter 기반 유튜브 라이브 재생 (YTN, 연합뉴스TV)
- 채널 전환: 좌우 스와이프 + ◀ ▶ 버튼 + 채널명 오버레이
- 즐겨찾기 기본 프리셋 (KBS1, KBS2, MBC, SBS, EBS1, YTN)
- 데이터 절약 모드 (360p/480p/720p 해상도 설정)
- 마지막 시청 채널 자동 복원
- 어르신 친화 고대비 다크 테마 UI
- 앱 아이콘 플랫폼별 적용 (SVG → PNG)
