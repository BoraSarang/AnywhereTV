# ChannelManager 계획

## 개요
AnywhereTV 채널 리스트를 편집/관리하는 macOS 전용 개인 도구.
현재 버전 v2.4 — AI 검색/추천, 헬스체크, 고도화 편집 기능 포함.

## 기술 스택
- Flutter (macOS 전용)
- media_kit (HLS/YouTube/dash/audio 테스트 재생)
- Gemini HTTP (AI 어시스턴트/검색/추천)
- GitHub REST API (JSON 저장소 동기화)

## 저장소 구조
```
/Users/lee/Documents/Apps/AnywhereTV/
├── anywhere_tv/              (기존 Flutter 앱)
├── channel_manager/          (macOS 전용 편집기)
├── packages/shared/          (리졸버/로거 공유)
└── docs/
    └── channel-manager-plan.md
```

## 데이터 흐름
1. 실행 → GitHub에서 `channels_v{latest}.json` 다운로드
2. 편집 → 로컬에서 채널/카테고리 수정
3. 저장 → GitHub에 PUT (SHA 기반 충돌 방지, 자동 버전 증가)
4. AnywhereTV는 GitHub Pages 등에서 최신 JSON 참조

## JSON 포맷 (기존 channels_v5.json 확장)
```json
{
  "_version": 6,
  "_history": [
    {"version": 5, "date": "2026-07-30", "changes": ["add: MBC every1", "remove: SBS"]}
  ],
  "categories": ["지상파", "종편/보도", "케이블"],
  "channels": [...]
}
```

## 화면 구성
| 화면 | 설명 |
|------|------|
| MainScreen | 채널 목록 + 카테고리 사이드바 (라이브 카운트), 헬스체크/리포트, Undo/Redo, 일괄 편집, M3U, AI |
| AddChannelScreen | URL 붙여넣기 → 해석 → 테스트 → 카테고리 지정 (로고 검색 포함) |
| EditChannelScreen | 채널명, URL, 대체 URL, 카테고리 수정 (로고 검색 포함) |
| CategoryManager | 카테고리 CRUD + 순서 변경 |
| VersionHistory | 버전별 변경 내역 + 백업 Diff |
| HealthReport | 헬스체크 실패 채널 리포트 + 개별 재검사 |
| DiffScreen | 백업 vs 현재 비교 (추가/삭제/수정) |
| M3uImportScreen | M3U 가져오기 미리보기 + 카테고리 매핑 |
| AiAssistantScreen | 자연어 명령 → Diff 미리보기 → 적용 |
| AiChannelSearchScreen | AI 채널 추천 (자연어 검색 탭 + 사이트 URL 조사 탭, ⌘1/⌘2/⌘F/Esc) |
| Settings | GitHub 토큰, Gemini API 키, 자동 헬스체크 |

## v2.4 신규 기능 (2026-08-18, 완료)
- T-128 AI 로고/채널명 검색 (AiSearchService — Gemini web search, 429/403 시 유튜브 검색 파싱 폴백)
- T-129 AI 채널 추천 (자연어 검색 탭)
- T-130 AI 채널 추천 (사이트 URL 조사 탭)
- T-131 소스 타입 dash/audio 확장
- T-133 브랜드 com.borasarang 전면 교체
- T-134 macOS 디자인 표준 (단축키·스페이싱·호버·밀도, deprecation 정리)

## v2.3 신규 기능 (2026-08-15, 완료)
- T-118 스트림 헬스체크 (HealthService, 상태 아이콘, 리포트)
- T-119 중복/무결성 검사 (ValidationService)
- T-120 Undo/Redo + 자동 백업 (Application Support)
- T-121 일괄 편집 (다중 선택 → 이동/삭제)
- T-122 로고 자동 완성 (iptv-org)
- T-123 백업 Diff 비교
- T-124 M3U 가져오기/내보내기
- T-125 라이브 대시보드 (카테고리 라이브 카운트 + 5분 자동 검사)
- T-126 AI 어시스턴트 (Gemini, Diff 미리보기 후 적용)
- T-127 대체 URL 페일오버 (backupStreamUrl, 어디서나TV 재생 폴백)

## 다음 (제안)
- AI 추천 결과 → 원클릭 채널 추가 (자동 소스 타입/카테고리 매핑)
- AI 검색 결과 캐시 (LLM 호출 절약, 429 방지)
- 사이트 조사 탭 유튜브 폴백 (무료 티어 지원)
