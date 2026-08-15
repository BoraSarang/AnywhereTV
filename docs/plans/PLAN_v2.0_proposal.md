# AnywhereTV v2.0 — 개선 제안서 (리서치 기반)

> 버전: v2.0.0-proposal
> 작성일: 2026-08-15
> 상태: 승인됨 (사용자 확인 완료) — 순서: 문서화 → 지역화 → P4 → P3 → P1 → P2 → P0

---

## 1. 개요

현재 AnywhereTV(v1.2.1)는 Flutter 기반 macOS + Android 실시간 TV 앱으로,
방송사 공식 무료 스트림 + YouTube InnerTube API를 사용하고 있다.
본 문서는 유사 프로젝트 리서치를 바탕으로 도출한 개선점/신규 기능을
우선순위별로 정리한 제안서다.

## 2. 경쟁/유사 프로그램 리서치 결과

| 프로젝트 | 플랫폼 | 핵심 기능 | 시사점 |
|---|---|---|---|
| clubTivi (Flutter, 89★) | 전 플랫폼 | 멀티소스 자동 페일오버, 4-tier EPG 매칭, 타임라인 가이드, Drift(SQLite), M3U/Xtream 파서 | EPG 매칭·멀티소스·로컬 DB 고도화 참고 |
| whiteTV (Flutter) | Apple TV/Android TV | M3U+EPG+timeshift, QR 리모컨, 플레이 히스토리 | TV 리모컨 대응 + 시청기록 참고 |
| TiviMate (상업) | Android TV | 7일 EPG 타임라인, DVR, 멀티뷰(9채널), catch-up, instant zapping | EPG/녹화의 사실상 표준 |
| IPTV Smarters Pro | 전 플랫폼 | 무료, catch-up, 다중 프로필 | 무료 + 기능 균형 참고 |
| xlivetv / alltv | Android TV | 웨이브·티빙 로그인 시청 | 유료 구독 필요 — AnywhereTV는 무료 차별점 |
| epg2xml / ko-epggrab | 서버 | 한국 EPG (KT/LG/NAVER/WAVVE/TVING → XMLTV) | **한국 EPG 공급원** |
| IPTV-org/iptv, Free-TV/IPTV | — | 전 세계 무료 채널 M3U 오픈 컬렉션 | 한국 채널 목록 확장 활용 |
| dpad (pub.dev) | Flutter | TV D-pad 내비게이션 패키지 | Android TV Leanback 구현에 사용 |

**AnywhereTV 차별 포인트**: 방송사 공식 API 직접 해석 리졸버 + 무료 + 어르신 친화 UI.
**부족한 점**: EPG, 채널 수, TV 플랫폼 대응, 테스트.

---

## 3. 제안 목록 (우선순위순)

### P0 — 품질 (안정성 기반)

| T-번호 | 항목 | 내용 | 예상 공수 |
|---|---|---|---|
| T-101 | 코드 중복 제거 | `stream_resolver.dart`가 앱/ChannelManager에 완전 중복 → 공유 패키지(`packages/shared/`) 추출 | 1h |
| T-102 | 자동 테스트 도입 | 리졸버 단위 테스트(모의 HTTP), ChannelRepository 캐시 테스트, 위젯 테스트 | 1.5h |
| T-103 | 리졸버 헬스체크 | GitHub Actions cron → 리졸버 URL 검증 → Gist 갱신 | 1h |
| T-104 | 에러 코드 체계화 | AGENTS.md 8.5 규격 `E-{PLATFORM}-{CAT}-{NUM4}` + error_message_ko.json | 30m |

### P1 — EPG 고도화 (최대 가치)

| T-번호 | 항목 | 내용 | 예상 공수 |
|---|---|---|---|
| T-105 | 한국 EPG 연동 | channels.json `epgUrl` + epg2xml/TVING·WAVVE·NAVER 소스 → 채널 리스트 "현재 방영중" 표시 | 1.5h |
| T-106 | 편성표 뷰 | 타임라인 그리드 (TiviMate 스타일) | 1.5h |
| T-107 | SQLite(Drift) | EPG 캐시 + 시청 기록 기반 (SharedPreferences 한계 극복) | 1h |

### P2 — 채널/콘텐츠 확장

| T-번호 | 항목 | 내용 | 예상 공수 |
|---|---|---|---|
| T-108 | 채널 확장 | 종편(JTBC·MBN·TV조선·채널A — 유튜브 라이브), KBS24/KBS NEWS, SBS Biz/Sports, 케이블 뉴스, 국회방송/KTV → 30~50개 | 1.5h |
| T-109 | 라디오 채널 | tbs FM, KBS 라디오 등 무료 스트림 (media_kit 오디오 지원) | 30m |
| T-110 | iptv-org 교차 검증 | 한국 채널 목록 교차 + 리졸버 자동 검증 파이프라인 | 1h |

### P3 — TV 경험 (v1.3 로드맵)

| T-번호 | 항목 | 내용 | 예상 공수 |
|---|---|---|---|
| T-111 | Android TV D-pad | `dpad` 패키지로 리모컨 내비게이션 | 1.5h |
| T-112 | PiP | Android 8.0+ `supportsPictureInPicture` | 1h |
| T-113 | 채널 즉시 전환 | 스트림 캐시 유지로 전환 지연 단축 | 1h |

### P4 — 어르신 UX (차별화)

| T-번호 | 항목 | 내용 | 예상 공수 |
|---|---|---|---|
| T-114 | TTS 음성 안내 | `flutter_tts` — 채널 전환/프로그램명 음성 출력 | 1h |
| T-115 | 즐겨찾기 재정렬 | 드래그 앤 드롭 순서 변경 | 30m |
| T-116 | 시청 기록 | 최근 본 채널 표시 | 30m |
| T-117 | 방송 시작 알림 | EPG 기반 로컬 알림 (v1.2+ 연동) | 1h |

### P5 — 플랫폼 확장

| T-번호 | 항목 | 내용 | 예상 공수 |
|---|---|---|---|
| T-118 | iOS/iPad | `media_kit_libs_ios_video`, iPad 적응형 | 2h |
| T-119 | Web/PWA | HLS.js 대체 (CORS 검증 필요) | 2h |

### 별도 — 지역화 (T-100)

| T-번호 | 항목 | 내용 |
|---|---|---|
| T-100 | 앱 표시 이름 지역화 | 시스템 언어에 따라 한글/영문 표시 (macOS+Android+iOS+ChannelManager) |

---

## 4. 실행 순서 (승인된 우선순위)

```
T-100 지역화 → P4 (T-114~117) → P3 (T-111~113) → P1 (T-105~107) → P2 (T-108~110) → P0 (T-101~104)
```

각 단계: 문서 우선 → 코딩 → flutter analyze → build_and_run.sh → DebugPanel 확인 → CHANGELOG/TODO 업데이트.

## 5. 롤백 계획

- 지역화: pbxproj 편집 실패 시 git revert + `xcodebuild -list` 재검증
- 각 기능: git revert + 해당 T-번호 TODO 상태 복구
- EPG: Gist 채널 데이터 원복 (버전 히스토리 활용)