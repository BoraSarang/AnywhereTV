# PLAN_v2.4_channel_manager — AI 검색·추천 + 소스 타입 확장

- 작성일: 2026-08-15
- 플랫폼: [macos] channel_manager (+ anywhere_tv 영향 검토)
- 상태: 승인 완료 (사용자 2026-08-15)
- 관련 문서: docs/TODO.md, docs/PLAN.md, PLAN_v2.3_channel_manager.md

## 1. 개요
채널 매니저 실사용 테스트(TC-MAN-001~009) 완료 후, 사용자 요청 3건:
1. **AI 로고/채널명 자동 검색** — 채널명 기반으로 인터넷 검색 → 후보 여러 개 → 선택 시 로고(썸네일)+채널명+핸들 자동 반영 (수정·추가 공용)
2. **AI 채널 추천** — ① 자연어 입력 → AI 검색 → 후보 목록 → 테스트 → 추가 / ② 특정 사이트 URL → AI 조사 → 라이브 채널 목록 → 테스트 → 추가
3. **라이브 채널 종류 리서치** — YouTube/HLS 외 추가 가능 종류 조사 (결과: Icecast 라디오/MPEG-DASH/직접 MP4·TS → sourceType 확장)

## 2. 사전 조사 결과(검증된 사실)
- 재생 엔진 media_kit(MPV): HLS/MP4/MP3/AAC/DASH/RTSP 사실상 전부 재생 → "소스 타입 라벨 + streamUrl 저장"만 추가하면 재생 가능. 별도 엔진 작업 불필요
- Gemini `generateContent` + `"tools": [{"google_search": {}}]` → 현재 모델(gemini-3.5-flash, 3.1-flash-lite) 전부 웹 검색 지원. **과금: Gemini 3는 검색 1회당 소액** → 자동 검색 금지, 명시적 버튼만
- 유튜브 채널 메타(채널ID/핸들/썸네일)는 검색 후보 선택 후 `ytInitialData` 직접 파싱 (stream_resolver.dart:226-244의 brace-depth JSON 파싱 패턴 재사용)
- 기존 로고 검색: iptv-org 한국 M3U 로컬 매칭만 (`logo_service.dart`) — 유튜브 전용 채널 미검색이 한계
- 채널 모델 `sourceType`은 문자열 ('hls','youtube_live','youtube','youtube_handle') — enum 아님. 어디서나TV player_screen은 sourceType 무관하게 streamUrl 있으면 그대로 재생
- AI 어시스턴트 프롬프트의 채널 필드 목록에 sourceType 포함되어 있어 dash/audio 문자열 자연스럽게 허용

## 3. 결정 사항
- **AI 검색은 반드시 명시적 버튼**으로만 실행 (비용 가드). 다이얼로그/화면에서 자동 검색 없음
- AI 검색 결과는 **후보 목록**으로만 제시, 실제 채널 메타는 **유튜브 직접 파싱**으로 확정 (Gemini는 검색·후보 선별 담당)
- 로고 검색 반환 타입 `LogoSearchResult`로 확장: logoUrl + name? + handle? + channelId? (기존 호출부 2곳 수정)
- 소스 타입 확장: `dash`(.mpd), `audio`(.mp3/.aac/.ogg/.m4a — Icecast/직접 오디오). Twitch/아프리카TV/RTMP는 인증·보호 문제로 제외 (리서치 결론)
- 에러 코드: E-MAN-AI-1003(검색 해석 실패), E-MAN-AI-1004(유튜브 메타 파싱 실패)
- Gemini 키는 기존 `gemini_api_key` 재사용 (설정 화면 그대로)

## 4. 아키텍처
```
channel_manager/lib/
├── services/
│   ├── ai_search_service.dart        [신규] AiChannelCandidate + Gemini web search
│   ├── youtube_meta_service.dart     [신규] 유튜브 채널 페이지 ytInitialData 파싱
│   ├── logo_service.dart             (유지)
│   └── m3u_service.dart              detectSourceType에 dash/audio 추가
├── widgets/
│   └── logo_search_dialog.dart       [수정] iptv-org + AI 검색 통합, LogoSearchResult 반환
├── screens/
│   ├── ai_channel_search_screen.dart [신규] 채널 추천 (자연어/사이트 URL 탭)
│   ├── add_channel_screen.dart       [수정] 로고 AI 반영, dash/audio 처리
│   ├── edit_channel_screen.dart      [수정] 로고 AI 반영, 드롭다운 확장
│   └── main_screen.dart              [수정] 채널 추천 아이콘 추가
└── models/channel.dart               (sourceType 문자열 — 변경 없음)
```
T-번호 매핑: T-128(로고 AI) → T-129(추천 자연어) → T-130(사이트 조사) → T-131(소스 확장) → T-132(테스트/문서)

## 5. 구현 단계(T-번호)

### T-128 AI 로고/채널명 검색
- `youtube_meta_service.dart`: `YoutubeChannelMeta{name, channelId, handle, avatarUrl, description}` + `fetch(String url)` — GET 유튜브 채널/핸들 페이지 → `ytInitialData` brace-depth 파싱:
  - `header.c4TabbedHeaderRenderer.title` → 이름
  - `metadata.channelMetadataRenderer.{channelId, description}` / `externalId` → 채널ID
  - `header.c4TabbedHeaderRenderer.avatar.channelThumbnailViewModel.thumbnail.thumbnails[0].url` → 썸네일
  - handle은 입력 URL에서 유지
- `ai_search_service.dart`: `AiChannelCandidate{name, description, channelUrl, logoUrl?, platform}` + `searchChannels({apiKey, query, siteUrl?})`:
  - 프롬프트(자연어): "다음 검색어의 라이브 TV/유튜브 채널을 검색 도구로 찾아 JSON 배열만 반환 [{name, description, url, platform}]"
  - 프롬프트(사이트): "URL {siteUrl}에서 시청 가능한 라이브 채널을 검색해 JSON 배열만 반환"
  - tools: `[{"google_search": {}}]`, 응답 `candidates[0].content.parts[0].text` → JSON 배열 파싱 (코드블록 마커 제거)
- `logo_search_dialog.dart`: 반환 `LogoSearchResult`로 확장. 상단 [🔍 이름 검색][🤖 AI 검색] 버튼. AI 탭: 검색어 표시 → 후보 카드(썸네일+이름+설명) → 탭 → `YoutubeMetaService.fetch(channelUrl)` 로딩 → 선택 결과 pop. iptv-org 탭은 기존 동작(logoUrl만)
- 호출부: `add_channel_screen.dart`(로고+이름+핸들+채널ID 반영), `edit_channel_screen.dart`(동일) — AI 결과 선택 시 setState로 컨트롤러 채움
- 로그: `[AI] 채널 검색: {query} → {n}건`, `[AI] 유튜브 메타: {name} (@handle)`

### T-129 AI 채널 추천 (자연어)
- `ai_channel_search_screen.dart` 신규: Tab 1 "자연어 추천" — 텍스트필드 + [AI 검색] 버튼 → 후보 카드 리스트
- 카드: 썸네일(logoUrl 또는 회색 아이콘) + 이름 + 설명 + 플랫폼 배지 + [테스트 재생] [추가]
- 테스트: 후보 URL 해석 → `PlayerService.play(url)` + 미니 플레이어(PlayerService.controller)
- 추가: 유튜브 후보 → `YoutubeMetaService.fetch`로 채널ID/핸들/썸네일 확정 → 카테고리 선택 다이얼로그 → `Channel` 생성(중복 검사: handle/videoId/streamUrl/name) → `store.addChannel` → 스낵바

### T-130 AI 사이트 조사
- 같은 화면 Tab 2 "사이트 URL" — URL 필드 + [AI 조사] 버튼 → `AiSearchService.searchChannels(siteUrl:)` → 동일 카드/테스트/추가 흐름
- URL 검증: http(s):// 필수, 아니면 E-MAN-URL-1005 스낵바

### T-131 소스 타입 확장 (dash/audio)
- `add_channel_screen._detectSourceType`: `.mpd` → dash, `.mp3/.aac/.ogg/.m4a` → audio
- `_save()`: streamUrl 저장 조건 `hls` → `hls/dash/audio` 확장
- `edit_channel_screen` 드롭다운: ['hls','dash','audio','youtube_live','youtube','youtube_handle']
- `m3u_service.detectSourceType`: 동일 확장 (M3U 왕복에서 유지)
- 어디서나TV: streamUrl 있으면 그대로 재생 경로라 코드 변경 불필요 (검증만)

### T-132 테스트/문서
- unit test: AiSearchService JSON 파싱(샘플 응답), YoutubeMetaService ytInitialData 파싱(샘플 HTML), detectSourceType 확장
- TC-MAN-012~015 실측: AI 로고 검색 / 자연어 추천+추가 / 사이트 조사 / dash·audio 왕복
- docs/TODO.md, docs/CHANGELOG.md, PLAN_v2.3(에러코드 링크) 업데이트, error_message_ko.json

## 6. 테스트 계획 (TC-MAN)
| ID | 내용 | 방법 |
|----|------|------|
| TC-MAN-012 | AI 로고 검색 | 채널 편집 → 로고 🔍 → AI 검색 → 후보 선택 → 로고/이름/핸들 자동 반영 확인 |
| TC-MAN-013 | AI 채널 추천 | 자연어 입력 → 후보 목록 → 테스트 재생 → 추가 → 목록/카테고리 확인 |
| TC-MAN-014 | AI 사이트 조사 | URL 입력 → 후보 목록 → 추가 확인 |
| TC-MAN-015 | dash/audio 소스 타입 | 편집 드롭다운/URL 감지/M3U 왕복 유지 확인 |

## 7. 롤백 계획
- 커밋별 revert: `git revert` (T-128~131 각 커밋 분리)
- Gist는 저장 전 dirty 상태로 원복 가능, 스크린샷/세션 로그 보존

## 8. 성능 예산
- AI 검색: 1회 ≤20s (검색+응답), 결과 파싱 ≤1s. 유튜브 메타 파싱 ≤10s
- 메모리: 후보 목록 ≤50개, 카드 썸네일 지연 로딩

## 9. 에러 코드 (error_message_ko.json)
- E-MAN-AI-1003: "AI 검색 결과를 해석하지 못했습니다. 다시 시도해 주세요."
- E-MAN-AI-1004: "유튜브 채널 정보를 가져오지 못했습니다."
- E-MAN-URL-1005: "올바른 사이트 URL(http/https)을 입력해 주세요."

## 10. 문서 업데이트 목록
- [ ] docs/TODO.md (T-128~132)
- [ ] docs/plans/PLAN_v2.4_channel_manager.md (본 문서)
- [ ] docs/CHANGELOG.md (v2.4.0, [macos] 태그)
- [ ] error_message_ko.json
- [ ] /.agent/session-2026-08-15-macos-5.md
