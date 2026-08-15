# PLAN v2.3 — Channel Manager 고도화

> 작성일: 2026-08-15
> 플랫폼: channel_manager (macOS Flutter) + T-127 한정 anywhere_tv (macOS/Android)
> 상태: 승인 완료 — P0 → P1 → P2 전체 진행 (2026-08-15 사용자 승인)
> 관련: `docs/channel-manager-plan.md`, `docs/TODO.md`, `docs/CHANGELOG.md`

## 1. 개요

AnywhereTV Channel Editor(macOS 전용)의 기능을 고도화한다.
리서치(m3u-editor, m3ueditor.com, m3ustudio, kamalsoft/m3u-editor, M3U_Manager-v3 등) 기반으로
P0(필수) / P1(생산성) / P2(차별화) 3단계 10개 작업을 진행한다.

## 2. 사전 조사 결과 (검증된 사실)

- 저장소: GitHub **Gist** `949188737a97773ad5313d9cbd159bff` (파일 `channels.json`) — 레포지토리 아님
- JSON 포맷: `version / updatedAt / remoteUrl / categories / history / channels`
- Channel 모델 필드: `id, name, logoUrl, streamUrl, youtubeChannelId, youtubeVideoId, youtubeHandle, category, sourceType, isDefaultFavorite, resolver, resolverData`
- 드래그앤드롭 채널 재정렬: **이미 구현됨** (`main_screen.dart` ReorderableListView + `channel_store.dart reorderChannels`) → 제안 목록에서 제외
- 헬스체크: `scripts/healthcheck_resolvers.py` (T-103) 존재 — KBS API + 정적 HLS + 유튜브 핸들 — Dart로 포팅 필요
- 채널 수: 39개 (v2.2 기준)

## 3. 결정 사항

1. T-118~T-120(P0) → T-121~T-124(P1) → T-125~T-127(P2) 순서로 진행
2. T-126: Gemini API 키를 설정 화면에 입력받는 방식 (하드코딩 금지, SharedPreferences 저장)
3. T-127: **어디서나TV 재생 로직까지 수정** — Channel 모델에 `backupStreamUrl` 추가, 재생 실패 시 폴백
4. 모든 신규 기능은 DebugLogger/기존 로깅 패턴 준수, 에러 코드는 `E-MAN-*` 사용 (CHR/SRV 아님, channel_manager 플랫폼 코드 MAN)
5. Undo/Redo는 스냅샷 기반, 최대 50개 스택, Cmd+Z / Cmd+Shift+Z

## 4. 아키텍처

```
channel_manager/lib/
├── services/
│   ├── health_service.dart        # T-118: 스트림 헬스체크 (HLS/유튜브/KBS)
│   ├── validation_service.dart    # T-119: 중복/무결성 검사
│   ├── backup_service.dart        # T-120: 자동 백업 (Application Support)
│   ├── m3u_service.dart           # T-124: M3U 파싱/생성
│   ├── diff_service.dart          # T-123: JSON Diff (추가/삭제/수정)
│   └── ai_assistant_service.dart  # T-126: Gemini 자연어 명령
├── widgets/
│   ├── health_badge.dart          # T-118: 채널 행 상태 아이콘
│   └── multi_select_list.dart     # T-121: 일괄 편집 선택 모드
└── screens/
    ├── health_report_screen.dart  # T-118: 실패 채널 리포트
    ├── diff_screen.dart           # T-123: 버전 비교 화면
    └── ai_assistant_screen.dart   # T-126: AI 대화 화면
```

## 5. 구현 단계 (T-번호)

### T-118 — 스트림 헬스체크 통합 (P0)
- `HealthService`: 채널별 검사 함수
  - HLS (`streamUrl` .m3u8): GET 첫 바이트가 `#EXTM3U` → OK, 아니면 실패
  - `youtube_handle`: `https://www.youtube.com/@{handle}/live` GET 200 → OK
  - `youtube` (videoId): `youtube.com/watch?v={id}` 접근 확인
  - KBS resolver: `https://cfpwwwapi.kbs.co.kr/api/v1/landing/live/channel_code/{code}` (resolverData에서 code)
  - 라디오 등 기타: streamUrl HEAD/GET 확인
- timeout 10초/채널, 동시 4개 (`Future.wait` + 배치), HTTP 403/429 대비 User-Agent 헤더
- `HealthStatus { ok, failed, unknown }` + `latencyMs`
- UI: 채널 행 앞 상태 아이콘 (🟢/🔴/⚪), 상단 앱바 "전체 검사" 버튼(진행 시 스피너), 결과 SnackBar 요약
- `HealthReportScreen`: 실패 채널 목록 + 실패 사유 + 재검사 버튼
- 결과 캐시: `Map<String, HealthStatus>` (채널 id → 상태), 저장 안 함

### T-119 — 중복/무결성 검사 (P0)
- `ValidationService.validate(channels, categories)` → `List<ValidationIssue>`
  - 이름 중복 (대소문자 무시), id 중복, streamUrl 중복, youtubeHandle 중복, youtubeVideoId 중복
  - 필수 필드 누락: name 빈값, category 없음, (streamUrl/youtubeHandle/youtubeVideoId 모두 없는 채널 → 소스 없음)
- 호출 시점: 저장 전 다이얼로그, 저장 후 변경점 요약
- UI: 문제 있는 채널 행에 경고 뱃지 (⚠️ + 툴팁), 채널 행 툴팁에 중복 정보

### T-120 — Undo/Redo + 자동 백업 (P0)
- `ChannelStore`에 스냅샷 스택: `_undoStack`, `_redoStack` (채널+카테고리+버전 전체 상태, 최대 50)
- 모든 변이 메서드(add/update/remove/addCategory/renameCategory/deleteCategory/reorder)에서 push
- `undo()`, `redo()`: 스냅샷 복원 + notifyListeners
- UI: 앱바 Undo/Redo 버튼 (활성 여부), `Shortcuts`/`Actions`로 Cmd+Z / Cmd+Shift+Z
- `BackupService`: 저장(saveToRemote) 성공 시 `~/Library/Application Support/AnywhereTVChannelEditor/backups/channels_v{n}_{yyyyMMdd_HHmmss}.json` 저장, 최근 20개 유지
- main.dart에서 Application Support 디렉토리 생성

### T-121 — 일괄 편집 (P1)
- 목록에 선택 모드 토글 (앱바 아이콘): 채널 행 체크박스 + 상단 선택 바 (선택 N개, 카테고리 이동, 삭제, 취소)
- 카테고리 이동: 다이얼로그로 카테고리 선택 → `store.updateChannel` 일괄
- 삭제: 확인 다이얼로그 → `store.removeChannel` 일괄 (선택 역순)
- 헬스체크 필터 연동: "실패 채널만 선택" 버튼 (T-118 결과 재사용)

### T-122 — 로고 관리 (P1)
- 로고 URL 유효성 검사: `HealthService.checkLogo(logoUrl)` — GET 200 + Content-Type image/* (헬스체크에 통합, 검사 대상 채널 로고 포함)
- iptv-org 자동 완성: 채널 이름 기반으로 `https://iptv-org.github.io/iptv/index.country.kr.m3u` (또는 채널 별 로고 패턴) 검색 — 구현은 채널명 매칭 + tvg-logo 추출, 결과 제안 다이얼로그
- 편집 화면(add/edit): 로고 URL 옆 미리보기(Image.network) + "검색" 버튼 → 제안 목록 → 선택 시 채우기

### T-123 — 플레이리스트 Diff (P1)
- `DiffService.diff(oldJson, newJson)`: id 기준 매칭 → added/removed/modified(name/category/url 변경) 목록
- `DiffScreen`: 백업 파일 선택 → 현재 JSON과 비교 결과 테이블 (추가=+green, 삭제=-red, 수정=변경 항목)
- 버전 히스토리 화면에서 "백업 비교" 버튼으로 진입 (최근 백업 자동 목록)

### T-124 — M3U 가져오기/내보내기 (P1)
- 내보내기: 파일 저장 다이얼로그(`save_file` 패키지 또는 macOS 파일 패널) → `#EXTM3U` 헤더 + `#EXTINF:-1 tvg-id=.. tvg-logo=.. group-title=..` + URL
  - 소스: streamUrl 또는 youtube_handle → `https://www.youtube.com/@handle/live`
- 가져오기: 파일 선택 → `#EXTINF` 파싱 (name, tvg-logo, group-title, URL) → 미리보기 화면 → 카테고리 매핑 → 일괄 추가
- 채널 변환: URL별 sourceType 자동 감지 (add_channel_screen의 _detectSourceType 로직 재사용)

### T-125 — 라이브 대시보드 (P2)
- 카테고리 사이드바 각 항목에 "● N" 라이브 카운트 (T-118 결과 기반)
- 상단 요약 바: 전체 N개 / 라이브 M개 / 오프라인 K개
- 주기적 자동 검사: 5분 간격 타이머 (설정에서 토글, 기본 off) — 검사 시 상태 갱신
- T-118 결과 캐시를 store 대신 ChangeNotifier로 분리해 위젯에서 구독

### T-126 — AI 어시스턴트 (P2)
- 설정 화면에 "Gemini API 키" 필드 추가 (SharedPreferences `gemini_api_key`, 보이기/숨기기)
- `AiAssistantService`: `POST https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key={key}`
  - 시스템 프롬프트: 채널 JSON 스키마 + 카테고리 목록 + 변경은 JSON 작업으로 표현하도록 지시
  - 요청: 현재 channels/categories JSON + 사용자 자연어 명령
  - 응답: JSON 액션 목록 파싱 → `AiAction { type: add|update|remove|move|rename, ... }` 실행 전 적용
- `AiAssistantScreen`: 채팅 UI (명령 입력 → 미리보기 Diff 표시 → 적용/취소)
- 에러: 키 없음 E-MAN-AUTH-1001, API 실패 E-MAN-AI-1002
- 참고: `docs/AI_MODELS.json` 모델 설정 재사용

### T-127 — 대체 URL 페일오버 (P2, 범위 확장)
- Channel 모델에 `backupStreamUrl` 추가 (channel_manager + anywhere_tv 둘 다)
  - `channel.dart` (channel_manager) + `channel.dart` (anywhere_tv) — 양쪽 필드/직렬화
- channel_manager: 편집 화면에 "대체 URL" 입력 필드, 헬스체크에서 backup도 검사 (라벨 "대체")
- anywhere_tv: 재생 실패 시 폴백 로직
  - `player_screen.dart` 또는 스트림 로드 함수: primary 실패 → `backupStreamUrl` 로드 시도 → 재생
  - 자동 재연결(기존 3회 재시도) 실패 후 backup 재시도 1회, 성공 시 재생 + 사용자 안내 스낵바
  - 실패 시 기존 에러 코드 E-COM-NET-1003 유지 (백업 실패 메시지 추가)

## 6. 테스트 계획 (TC-번호)

| TC | 내용 | 방법 |
|----|------|------|
| TC-MAN-001 | 헬스체크: 실제 39개 채널 → HLS/유튜브 상태 분류 정확성 | 앱 실행 실측 + 결과 요약 |
| TC-MAN-002 | 중복 검사: 동일 URL 2개 추가 → 저장 전 경고 표시 | 단위 + UI 실측 |
| TC-MAN-003 | Undo/Redo: 채널 삭제→undo 복원→redo 재삭제, Cmd+Z 동작 | UI 실측 |
| TC-MAN-004 | 자동 백업: 저장 후 백업 파일 생성 + 최근 20개 유지 | 파일시스템 확인 |
| TC-MAN-005 | 일괄 편집: 5개 선택→카테고리 이동→목록 반영 | UI 실측 |
| TC-MAN-006 | M3U 왕복: 내보내기→가져오기→채널 39개 복원 | 실측 |
| TC-MAN-007 | Diff: 백업 파일 vs 현재 → 추가/삭제/수정 표시 | UI 실측 |
| TC-MAN-008 | AI: "MBC 채널을 케이블로 이동" → Diff 미리보기 → 적용 | API 키 사용 실측 |
| TC-MAN-009 | 폴백: streamUrl 끊긴 채널 재생 → backupStreamUrl 재생 확인 | 어디서나TV 실측 |
| TC-MAN-010 | 검증: `flutter analyze` 신규 0, `flutter build macos --debug` 성공 | CLI |
| TC-MAN-011 | 검증(T-127): `./build_and_run.sh debug android` 성공 | CLI |

## 7. 롤백 계획

- 커밋별 분리 (T-118~T-127 각각) → 문제 시 `git revert`
- Gist 원복: 이전 버전 JSON을 채널 매니저에서 수동 업로드
- 어디서나TV 폴백 제거: `backupStreamUrl` 필드만 제거하면 기존 동작 유지 (옵셔널 필드라 하위호환)
- 백업 파일에서 복구: `BackupService` 백업으로 Undo 불가 시 복구

## 8. 성능 예산

| 지표 | 목표 |
|------|------|
| 헬스체크 전체 검사 (39채널) | ≤ 60초 (동시 4, timeout 10s) |
| 채널 행 렌더링 | 변경 없음 (기존 성능 유지) |
| 앱 시작 시간 | 변화 없음 (백업/검사는 저장/요청 시에만) |
| 메모리 | 스냅샷 50개 × 채널 40개 × ~1KB ≈ 2MB 이하 |

## 9. 에러 코드 (error_message_ko.json 추가)

| 코드 | 메시지 |
|------|--------|
| E-MAN-AUTH-1001 | AI 어시스턴트를 사용하려면 설정에서 Gemini API 키를 입력하세요. |
| E-MAN-AI-1002 | AI 요청에 실패했습니다. 다시 시도해 주세요. |
| E-MAN-BACK-1001 | 백업을 만들지 못했습니다. 저장은 계속 진행됩니다. |
| E-MAN-M3U-1001 | M3U 파일을 읽을 수 없습니다. 형식을 확인해 주세요. |

## 10. 문서 업데이트 목록

- [x] `docs/plans/PLAN_v2.3_channel_manager.md` (본 문서)
- [ ] `docs/TODO.md` — T-118~T-127 등록 (작성 중)
- [ ] `docs/CHANGELOG.md` — v2.3 기록 (완료 후)
- [ ] `docs/channel-manager-plan.md` — 신규 기능 반영 (완료 후)
- [ ] `error_message_ko.json` — E-MAN-* 추가
