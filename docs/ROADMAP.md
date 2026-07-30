# 어디서나 TV — 로드맵

> 최종 업데이트: 2026-07-30

## 버전 역사

| 버전 | 일자 | 주요 변경 |
|------|------|----------|
| v1.0.0 | 2026-07-29 | 첫 릴리즈: 8개 채널, HLS/YouTube 재생, 즐겨찾기 |
| v1.1.0 | 2026-07-29 | 28개 채널, media_kit_libs_android, 서명 APK, 생명주기 처리 |
| **v1.2.0** | **진행중** | **EPG + 백그라운드 재생 + 자동 재연결** |

---

## v1.2.0 — "EPG + 안정성"

### 목표
시청자에게 **"지금 뭐 틀지?"** 정보를 제공하고, 앱을 나갔다 들어와도 끊김 없이 시청 가능하게 함.

### 범위

#### EPG (전자 프로그램 가이드)
사용자가 채널을 고르기 전에 **현재 방영중인 프로그램**을 알 수 있어야 함.

- [ ] **EPG 데이터 모델**: `EpgProgram` (channelId, title, startTime, endTime, description, category)
- [ ] **EPG 소스**: channels.json에 `epgUrl` 필드 추가 → XMLTV 또는 JSON 스케줄 파싱
- [ ] **YouTube EPG**: YouTube 채널의 현재/예정 라이브스트림 정보 표시 (youtubei/v1/player 응답 활용)
- [ ] **플레이어 오버레이**: 현재 재생중인 채널에 프로그램명 표시
- [ ] **채널 리스트**: 각 채널 타일에 "현재 방송중" 프로그램명 표시
- [ ] **편성표 화면**: 타임라인 뷰 (선택)

#### 백그라운드 재생 (Android)
앱을 나가도 소리가 계속 나와야 함 (음악 앱처럼).

- [ ] **Android Foreground Service**: 알림 표시 + play/pause 컨트롤
- [ ] **오디오 포커스**: 전화/다른 앱과 충돌 방지
- [ ] **macOS**: media_kit이 기본 지원 (별도 작업 불필요)

#### 자동 재연결
스트림이 끊겨도 사용자가 직접 "재시도" 누르지 않아도 됨.

- [ ] **Player error 감지**: `Player.stream.error` / `Player.stream.position` 구독
- [ ] **자동 Retry**: 3초 대기 → 최대 3회 재시도, "재연결 중..." UI
- [ ] **네트워크 변경 감지**: WiFi→LTE 전환시 자동 재연결

#### 검색
채널이 많아졌을 때 빠르게 찾기.

- [ ] **채널 리스트 검색바**: 이름/카테고리 필터링
- [ ] **키보드 지원**: desktop에서 타이핑 즉시 검색

### 제외 (v1.2.0 범위 밖)
- PiP (Picture-in-Picture) — v1.3.0
- Android TV Leanback — v1.3.0
- iOS 지원 — v1.4.0
- Web 지원 — v1.5.0

### 일정

| 단계 | 내용 | 예상 시간 |
|------|------|----------|
| 1 | EPG 데이터 모델 + channels.json epgUrl | 30분 |
| 2 | EPG 소스 (XMLTV/JSON 파서) | 1시간 |
| 3 | EPG UI (오버레이 + 채널 리스트) | 1시간 |
| 4 | 백그라운드 재생 (Android) | 1시간 |
| 5 | 자동 재연결 | 30분 |
| 6 | 검색 | 30분 |
| 7 | 빌드 + 테스트 + 릴리즈 | 30분 |

---

## v1.3.0 — "TV 경험"

- PiP (Picture-in-Picture) Android
- Android TV Leanback UI (리모컨 D-pad)
- 자동 업데이트 체크
- 통계/크래시 리포팅 (선택)

## v1.4.0 — "Apple 생태계"

- iOS 빌드 (media_kit_libs_ios_video)
- iPad 적응형 레이아웃

## v1.5.0 — "웹"

- Web 빌드 (HLS.js로 대체)
- PWA 오프라인 지원
