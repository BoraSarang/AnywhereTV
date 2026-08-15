# 변경 이력 (CHANGELOG)

## v2.3.0 (2026-08-15) — Channel Manager 고도화 (P0~P2)

> 계획: `docs/plans/PLAN_v2.3_channel_manager.md`

### feat [channel_manager][macos]
- T-118 스트림 헬스체크: `HealthService` — 리졸버 호출(KBS/SBS/MBC/유튜브) + HLS 매니페스트 첫 바이트 확인, 동시 4개 검사, 채널 행 상태 아이콘, 전체 검사 버튼, 실패 리포트 화면(개별 재검사/테스트 재생)
- T-119 중복/무결성 검사: `ValidationService` — 이름/id/스트림 URL/핸들/동영상 중복, 필수 필드 누락, 로고 URL 형식 — 저장 전 경고 다이얼로그 + 채널 행 경고 뱃지
- T-120 Undo/Redo + 자동 백업: 스냅샷 스택(최대 50) + Cmd+Z / Cmd+Shift+Z 단축키, 저장 시 `~/Library/Application Support/AnywhereTVChannelEditor/backups/`에 자동 백업(최근 20개 유지)
- T-121 일괄 편집: 선택 모드(체크박스) → 카테고리 일괄 이동/삭제, "실패 채널만 선택" 필터
- T-122 로고 관리: iptv-org 한국 목록 기반 로고 자동 완성 검색(추가/편집 화면), 로고 URL 형식 검증
- T-123 플레이리스트 Diff: 백업 파일 vs 현재 비교(추가/삭제/수정, 변경 필드 표시) — 버전 기록에서 진입
- T-124 M3U 가져오기/내보내기: `file_selector`(entitlements read-write 추가), 가져오기는 미리보기+카테고리 매핑 후 일괄 추가
- T-125 라이브 대시보드: 카테고리별 라이브 카운트, 온라인/오프라인 요약 바, 5분 자동 검사(설정 토글)
- T-126 AI 어시스턴트: Gemini API 키 설정(SharedPreferences), 자연어 명령 → 수정된 JSON → Diff 미리보기 → 적용(Undo 가능). 에러: E-MAN-AUTH-1001, E-MAN-AI-1002
- T-127 대체 URL 페일오버: Channel `backupStreamUrl` 필드(양쪽 앱) — 편집 화면 입력, 헬스체크 백업 검사, 어디서나TV 재생 실패 시 백업 전환

### model
- Channel (channel_manager + anywhere_tv): `backupStreamUrl` 필드 추가 (fromJson/toJson/copyWith)

### test
- `test/services_test.dart` 7건: ValidationService 3건, DiffService 1건, M3uService 2건, backupStreamUrl 직렬화 1건 — 총 8건 통과

### docs
- `docs/plans/PLAN_v2.3_channel_manager.md` 신규
- `docs/channel-manager-plan.md` 기능 목록 갱신
- `error_message_ko.json`: E-MAN-AUTH-1001, E-MAN-AI-1002, E-MAN-BACK-1001, E-MAN-M3U-1001 추가

## v2.2.0 (2026-08-15) — EPG 연동 (P1)

### feat [macos][android]
- T-105 한국 EPG 연동:
  - `EpgService` XMLTV 파서 추가 (`package:xml`) — epg2xml 표준 `<programme>` 파싱, `+0900` 시간대 처리
  - 채널 리스트 각 채널 타일에 "현재 방영중" 프로그램명 표시 (epgUrl 기반)
  - 설정 화면에 EPG 서버 URL 입력 필드 추가 (전역 epgServerUrl, 채널별 epgUrl 우선)
  - 방송 시작 알림(T-117)도 전역 EPG 서버 URL 폴백 지원
- T-106 편성표 타임라인 뷰: 플레이어 상단 달력 버튼 → 오늘 24시간 편성표 그리드 (현재 시간 라인, 프로그램 상세 다이얼로그, 당겨서 새로고침)
- T-107 SQLite(Drift) 도입: `drift` + `sqlite3_flutter_libs` — EPG 캐시 테이블(6시간 TTL, 채널별) + 시청 기록 테이블(최대 20, SharedPreferences → Drift 이전). EPG fetch 실패 시 캐시 폴백
- T-108 채널 확장: 28 → 39개 — 종편(JTBC·MBN·TV조선·채널A), KBS NEWS 24, 국회방송, KTV (유튜브 라이브 핸들 검증 완료)
- T-109 라디오 채널 4개: TBN 경인교통방송, FEBC 서울극동방송, EBS FM, YTN 라디오 (정적 m3u8 검증 완료)
- T-110 데이터 검증 파이프라인: `test/channel_data_test.dart` — 채널 수/중복/필수 필드/sourceType별 필수값/핸들 형식 검증. 기존 2개 채널(@ 누락) 데이터 정합성 수정
- T-101 공유 패키지 추출: `packages/shared/` (`anywhere_shared`) — stream_resolver + debug_logger + stream_resolution_result 중복 제거, 두 앱 path 의존성으로 전환
- T-102 자동 테스트: 리졸버 variant 선택 단위 테스트(6건), ChannelRepository 캐시 테스트(5건), ChannelListScreen 위젯 테스트, channel_manager 스모크 테스트 — 총 23건 통과
- T-103 리졸버 헬스체크: `.github/workflows/resolver-healthcheck.yml` (6시간 cron) + `scripts/validate_channels.py` + `scripts/healthcheck_resolvers.py` (KBS API/라디오 HLS/유튜브 13개 체크)
- T-104 에러 코드 체계화: `error_message_ko.json` (E-COM-*) + `ErrorMessages` 서비스, PlayerScreen/편성표 에러 메시지 코드 매핑

### P0~P4 전체 완료
- 지역화(T-100) → 어르신 UX(T-114~117) → TV 경험(T-111~113) → EPG(T-105~107) → 채널 확장(T-108~110) → 품질(T-101~104) 전부 구현 완료

### model
- UserState: `epgServerUrl` 추가 (저장/로드 `setEpgServerUrl`)

### test
- `test/epg_service_test.dart`: XMLTV 파싱 4건 (채널 매칭, 접두사 매칭, 비매칭, 시간대 변환)

## v2.1.0 (2026-08-15) — 어르신 UX (P4)

### feat [macos][android]
- T-114 TTS 음성 안내: `flutter_tts` — 채널 전환 시 채널명·프로그램명 음성 출력 (설정 토글, ko-KR 느린 속도)
- T-115 즐겨찾기 드래그 재정렬: 채널 목록 상단 "즐겨찾기" 섹션 ReorderableListView (저장 순서 존중)
- T-116 시청 기록: 최근 본 채널 최대 10개 저장, 채널 목록 "최근 시청" 섹션 표시
- T-117 방송 시작 알림: 채널 `epgUrl` 기반 다음 프로그램 5분 전 SnackBar 알림 (1분 폴링, 설정 토글)

### model
- Channel: `epgUrl` 필드 추가
- UserState: `ttsEnabled`, `broadcastAlertsEnabled` 추가

## v2.0.0 (2026-08-15) — 앱 표시 이름 지역화

### feat [macos][ios][android]
- 앱 표시 이름 시스템 언어 자동 지역화:
  - AnywhereTV: 한국어 시스템 → `어디서나 TV`, 그 외 → `AnywhereTV`
  - ChannelManager: 한국어 시스템 → `AnywhereTV 채널 관리`, 그 외 → `Channel Manager`
- macOS/iOS: `CFBundleDisplayName` + `en.lproj/ko.lproj/InfoPlist.strings` (PBXVariantGroup 등록)
- Android: `values/strings.xml`(AnywhereTV) + `values-ko/strings.xml`(어디서나 TV) + manifest `@string/app_name`

### fix [ios]
- iOS Info.plist `CFBundleDisplayName` "Anywhere Tv" → "AnywhereTV" (기존 하드코딩 정리)

### 검증
- macOS Finder 표시 이름 확인: AnywhereTV.app → "어디서나 TV", channel_manager.app → "AnywhereTV 채널 관리" (ko-KR 시스템, mdls/Spotlight 기준)
- Android: aapt dump badging — default "AnywhereTV", ko "어디서나 TV"
- pbxproj plutil lint + xcodebuild -list 모두 통과

## v1.2.1 (2026-07-31) — 자막 디버깅 + 안정화

### fix
- MBC HLS 자막: mpv FFI로 `sub-visibility=no` 설정 성공 확인 → burned-in 한계로 결론
- FFI 코드 정리 및 불필요한 mpv 설정 제거

### known issues
- MBC HLS: 방송사 스트림에 자막이 영상에 박혀(burned-in) 있어 플레이어 레벨에서 제거 불가

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
- 번들 ID 통일: `com.borasarang.anywheretv` (macOS/iOS/Android)
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
