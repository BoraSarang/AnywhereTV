# 어디서나 TV — 구현 계획 (PLAN)

> 버전: 2.4.0
> 최종 업데이트: 2026-08-18
> 상세 제안: `docs/plans/PLAN_v2.0_proposal.md`, `docs/plans/PLAN_v2.3_channel_manager.md`, `docs/plans/PLAN_v2.4_channel_manager.md`
> 작업 추적: `docs/TODO.md` · 설계: `docs/DESIGN.md` · 로드맵: `docs/ROADMAP.md`

## 개요

Flutter + media_kit 기반 모노레포. macOS + Android 한국 실시간 TV 뷰어(어디서나TV)와
전용 macOS 채널 편집기(Channel Manager). 방송사 공식 스트림 + YouTube InnerTube API → HLS.

## 완료

### v2.4 — AI 채널 검색/추천 + 브랜드 교체
- [x] AI 로고/채널명 검색 (Gemini web search + 유튜브 파싱 폴백) — T-128
- [x] AI 채널 추천: 자연어 검색(T-129) + 사이트 URL 조사(T-130)
- [x] 소스 타입 dash/audio 확장 — T-131
- [x] 브랜드 com.borasarang 전면 교체 (번들ID/패키지/히스토리/데이터) — T-133
- [x] macOS 디자인 표준 (단축키·스페이싱·호버·밀도) — T-134

### v2.3 — Channel Manager 고도화 (T-118~127)
- [x] 스트림 헬스체크 · 중복/무결성 검사 · Undo/Redo+자동백업 · 일괄편집
- [x] 로고 관리 · 플레이리스트 Diff · M3U 가져오기/내보내기 · 라이브 대시보드
- [x] AI 어시스턴트(Gemini) · 대체 URL 페일오버(`backupStreamUrl`)

### v2.0 — 지역화 + 개선 (T-100~117)
- [x] 앱 표시 이름 지역화 · TTS · 즐겨찾기 드래그 · 시청 기록 · 방송 시작 알림
- [x] Android TV D-pad · PiP · 채널 즉시 전환(스트림 캐시)
- [x] 한국 EPG(현재 방영중) · 편성표 타임라인 · SQLite(Drift) · 채널 30~50개 · 라디오
- [x] iptv-org 교차 검증 + 리졸버 헬스체크 CI cron · 공유 패키지 추출 · 자동 테스트 · 에러 코드 체계화

### v1.x — MVP/안정화
- [x] Android + macOS 빌드/배포 파이프라인 · 28개 채널 (v6)
- [x] HLS + YouTube InnerTube 리졸버 (KBS/SBS/MBC/youtube/youtube_handle)
- [x] 즐겨찾기 + 카테고리 정렬 + 마지막 채널 복원 · 해상도 선택
- [x] DebugLogger + DebugPanel · Android 서명 APK (CI+로컬)
- [x] macOS 싱글 인스턴스 · INTERNET 퍼미션 · 생명주기 처리 · YouTube videoId 우선
- [x] EPG 프로그램명 광역 · 백그라운드 재생 · 자동 재연결 · 채널 검색 · 자막 디버깅

## 진행 예정 (제안)

- [ ] T-132: v2.4 실사용 테스트 (TC-MAN-012~015)
- [ ] AI 추천 결과 → 원클릭 채널 추가 / AI 검색 결과 캐시(429 방지)
- [ ] (후보) Android TV Leanback 정식 UI / iOS / Web + PWA
