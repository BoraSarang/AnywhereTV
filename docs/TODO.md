# 어디서나 TV — 작업 추적 (TODO)

> 최종 업데이트: 2026-08-18
> 현재 버전: v2.4.0 — AI 채널 검색/추천 + 브랜드 교체
> 상세 제안: `docs/plans/PLAN_v2.0_proposal.md`, `docs/plans/PLAN_v2.3_channel_manager.md`, `docs/plans/PLAN_v2.4_channel_manager.md`

## v2.4 — AI 채널 검색/추천 + 브랜드 교체

| T-번호 | 작업 | 상태 | 예상 시간 |
|--------|------|------|----------|
| T-128 | AI 로고/채널명 검색 (Gemini web search + 유튜브 파싱 폴백) | ✅ 완료 | 3h |
| T-129 | AI 채널 추천 화면 (자연어 검색) | ✅ 완료 | 2h |
| T-130 | AI 채널 추천 화면 (사이트 URL 조사) | ✅ 완료 | 1.5h |
| T-131 | 소스 타입 dash/audio 확장 | ✅ 완료 | 1h |
| T-132 | v2.4 실사용 테스트 (TC-MAN-012~015) | 🔄 진행 중 | 1h |
| T-133 | 브랜드 ID okstart → com.borasarang 전면 교체 (소스/히스토리/데이터 이전) | ✅ 완료 | 2h |
| T-134 | macOS 디자인 표준 적용 — 채널 추천 화면/로고 다이얼로그 (단축키·스페이싱·호버·밀도) | ✅ 완료 | 1h |

## v2.3 — Channel Manager 고도화 (전체 완료)

| T-번호 | 작업 | 상태 | 예상 시간 |
|--------|------|------|----------|
| T-118 | 스트림 헬스체크 통합 (HealthService + 상태 아이콘 + 실패 리포트) | ✅ 완료 | 3h |
| T-119 | 중복/무결성 검사 (ValidationService + 저장 전 경고 + 뱃지) | ✅ 완료 | 1.5h |
| T-120 | Undo/Redo + 자동 백업 (스냅샷 스택, Cmd+Z, BackupService) | ✅ 완료 | 2h |
| T-121 | 일괄 편집 (다중 선택 → 카테고리 이동/삭제) | ✅ 완료 | 1.5h |
| T-122 | 로고 관리 (유효성 검사 + iptv-org 자동 완성 제안) | ✅ 완료 | 1.5h |
| T-123 | 플레이리스트 Diff (백업 vs 현재 비교 화면) | ✅ 완료 | 1.5h |
| T-124 | M3U 가져오기/내보내기 | ✅ 완료 | 1.5h |
| T-125 | 라이브 대시보드 (카테고리 요약 + 5분 자동 검사) | ✅ 완료 | 1.5h |
| T-126 | AI 어시스턴트 (Gemini API 키 설정 + 자연어 명령 → Diff 적용) | ✅ 완료 | 2h |
| T-127 | 대체 URL 페일오버 (backupStreamUrl + 어디서나TV 재생 폴백) | ✅ 완료 | 2h |

## v2.0 — "지역화 + 개선" (전체 완료)

| T-번호 | 작업 | 상태 | 예상 시간 |
|--------|------|------|----------|
| T-100 | 앱 표시 이름 지역화 (macOS/Android/iOS/ChannelManager) | ✅ 완료 | 2h |
| T-114 | TTS 음성 안내 (어르신 UX) | ✅ 완료 | 1h |
| T-115 | 즐겨찾기 드래그 재정렬 | ✅ 완료 | 30m |
| T-116 | 시청 기록 (최근 본 채널) | ✅ 완료 | 30m |
| T-117 | 방송 시작 알림 (EPG 연동) | ✅ 완료 | 1h |
| T-111 | Android TV D-pad 내비게이션 | ✅ 완료 (Android 태블릿 실측) | 1.5h |
| T-112 | PiP (Android) | ✅ 완료 (Android 태블릿 실측) | 1h |
| T-113 | 채널 즉시 전환 (스트림 캐시) | ✅ 완료 (Android 태블릿 실측) | 1h |
| T-105 | 한국 EPG 연동 (현재 방영중 표시) | ✅ done | 1.5h |
| T-106 | 편성표 타임라인 뷰 | ✅ done | 1.5h |
| T-107 | SQLite(Drift) 도입 | ✅ done | 1h |
| T-108 | 채널 확장 (종편/뉴스/라디오 30~50개) | ✅ done | 1.5h |
| T-109 | 라디오 채널 | ✅ done | 30m |
| T-110 | iptv-org 교차 검증 + 리졸버 검증 파이프라인 | ✅ done | 1h |
| T-101 | 공유 패키지 추출 (stream_resolver 중복 제거) | ✅ done | 1h |
| T-102 | 자동 테스트 도입 | ✅ done | 1.5h |
| T-103 | 리졸버 헬스체크 자동화 (CI cron) | ✅ done | 1h |
| T-104 | 에러 코드 체계화 | ✅ done | 30m |

## 완료 (v1.2.1)

- [x] 자막 디버깅 완료 (burned-in 한계 문서화)
- [x] EPG 프로그램명 오버레이 (InnerTube title)
- [x] 백그라운드 재생 (Android foreground)
- [x] 자동 재연결 (3회 재시도)
- [x] 채널 검색
- [x] 화면 회전 잠금

## 완료 (v1.1.0)

- [x] 27개 채널 설정 (v6)
- [x] HLS + InnerTube 리졸버 (KBS/SBS/MBC/youtube)
- [x] 즐겨찾기 + 카테고리 정렬
- [x] 마지막 채널 복원
- [x] 해상도 선택
- [x] DebugLogger + DebugPanel
- [x] Android 서명 APK (CI + 로컬)
- [x] macOS 싱글 인스턴스
- [x] INTERNET 퍼미션
- [x] 생명주기 처리 (백그라운드 복원)
- [x] YouTube videoId 우선 처리
- [x] media_kit_libs_android_video 추가