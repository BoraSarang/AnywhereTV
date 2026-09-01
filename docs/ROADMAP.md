# 어디서나 TV — 로드맵

> 최종 업데이트: 2026-08-18
> 현재 버전: v2.4.0 (AI 채널 검색/추천 + 브랜드 교체)

## 버전 역사

| 버전 | 일자 | 주요 변경 |
|------|------|----------|
| v1.0.0 | 2026-07-29 | 첫 릴리즈: 8개 채널, HLS/YouTube 재생, 즐겨찾기 |
| v1.1.0 | 2026-07-29 | 28개 채널, media_kit_libs_android, 서명 APK, 생명주기 처리 |
| v1.2.x | 2026-08 | EPG 연동, 백그라운드 재생, 자동 재연결, 채널 검색, 자막 디버깅 |
| v2.0.0 | 2026-08 | 지역화 + 개선: 한국 EPG, 편성표 타임라인, SQLite(Drift), 채널 30~50개, PiP, TTS, 방송 알림, 공유 패키지 |
| v2.2.0 | 2026-08-15 | EPG 고도화: 현재 방영중 표시, 편성표, Drift, 채널 39개 |
| v2.3.0 | 2026-08-15 | Channel Manager 고도화: 헬스체크·검증·Undo백업·일괄편집·로고·Diff·M3U·라이브대시보드·AI어시스턴트·대체URL |
| **v2.4.0** | **2026-08-18** | **AI 로고/채널명 검색(유튜브 폴백), AI 채널 추천(자연어/URL), 소스 타입 dash/audio, 브랜드 com.borasarang, macOS 디자인 표준** |

> 상세 버전별 작업: `docs/TODO.md` · 변경 내용: `CHANGELOG.md` · 상세 설계: `docs/DESIGN.md`

---

## 완료 (v2.4.0)

#### Channel Manager — AI 검색/추천
- [x] **AI 로고/채널명 검색** (`AiSearchService`): Gemini web search 기반 — 무료 티어 429/403 시 **유튜브 검색 결과 페이지 파싱으로 자동 폴백**
- [x] **AI 채널 추천 (자연어)**: 채널 추천 화면 자연어 검색 탭
- [x] **AI 채널 추천 (사이트 URL)**: URL 기반 조사 탭
- [x] **AI 모델 단일화**: `AiAssistantService.models` 단일 소스 — 어시스턴트/검색/추천 공유
- [x] **소스 타입 확장**: dash/audio 지원

#### 브랜드 & 디자인
- [x] **브랜드 교체**: 번들 ID `com.borasarang.*` (Android 패키지 이동 + git 히스토리 재작성 + 데이터 이전)
- [x] **macOS 디자인 표준**: 채널 추천/로고 다이얼로그 — 단축키(⌘1/⌘2/⌘F/Esc)·스페이싱·호버·밀도, deprecation 정리

---

## 완료 (v2.3.0) — Channel Manager 고도화

- [x] 스트림 헬스체크 (`HealthService` + 상태 아이콘 + 실패 리포트)
- [x] 중복/무결성 검사 (`ValidationService`) / Undo·Redo + 자동 백업
- [x] 일괄 편집 / 로고 관리(iptv-org 자동 완성) / 플레이리스트 Diff / M3U 가져오기·내보내기
- [x] 라이브 대시보드(5분 자동 검사) / AI 어시스턴트(Gemini) / 대체 URL 페일오버(`backupStreamUrl`)

## 완료 (v2.0) — 지역화 + 개선

- [x] 앱 표시 이름 지역화 / TTS 음성 안내 / 즐겨찾기 드래그 / 시청 기록
- [x] 방송 시작 알림(EPG) / Android TV D-pad / PiP / 채널 즉시 전환(스트림 캐시)
- [x] 한국 EPG(현재 방영중) / 편성표 타임라인 / SQLite(Drift) / 채널 30~50개 / 라디오
- [x] iptv-org 교차 검증 + 리졸버 헬스체크 CI cron / 공유 패키지 추출 / 자동 테스트 / 에러 코드 체계화

## 완료 (v1.2.x)

- [x] 자막 디버깅(burned-in 한계 문서화) / EPG 프로그램명 오버레이 / 백그라운드 재생
- [x] 자동 재연결(3회) / 채널 검색 / 화면 회전 잠금

---

## 다음 계획 (제안)

### 후보 1 — Channel Manager 확장
- 채널 추천 결과 → 원클릭 채널 추가(자동 소스 타입/카테고리 매핑)
- AI 검색 결과 캐시(LLM 호출 절약, 429 방지) — `[CACHE]` 예산 hit ≥70%
- 사이트 조사 탭의 유튜브 폴백 (무료 티어 지원)

### 후보 2 — 어디서나TV 앱 심화
- Android TV Leanback 정식 UI
- iOS 빌드 (media_kit_libs_ios_video)
- Web 빌드 + PWA 오프라인

### 후보 3 — 배포/품질
- 자동 업데이트 체크 (서명 추가 시)
- 크래시 리포팅

> 우선순위는 사용자 결정에 따름. 기능 추가 전 `docs/plans/PLAN_v*.md` 작성 후 진행.
