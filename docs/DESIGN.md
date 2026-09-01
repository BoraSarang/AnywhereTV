# 어디서나 TV — 기술 설계 (DESIGN)

> 버전: 2.4.0
> 최종 업데이트: 2026-08-18
> 브랜드: `com.borasarang.*` · GitHub `BoraSarang/AnywhereTV`

## 1. 기술 스택

| 영역 | 선택 |
|------|------|
| 프레임워크 | Flutter 3.44.6 (Dart 3.12.2), 모노레포 `pnpm-workspace.yaml` |
| 비디오 | media_kit 1.2.6 / media_kit_video 2.0.1 (libmpv MPV 엔진) |
| 채널 데이터 | GitHub Gist JSON (버전 + 히스토리 포함, 폴백 로컬 assets/channels.json) |
| 로컬 저장 (앱) | Drift(SQLite) + sqlite3_flutter_libs — EPG 캐시(TTL 6h)·시청 기록(최대 20) / shared_preferences |
| EPG | XMLTV 파서 (`package:xml`) — epg2xml 표준 `<programme>`, `+0900` |
| 백그라운드 | flutter_background_service (Android foreground notification) |
| TTS | flutter_tts 4.2.5 (어르신 친화 음성 안내) |
| AI (ChannelManager) | Gemini HTTP(vertex/ai platform generateContent) — `AiAssistantService.models` 단일 소스 |
| CI/CD | GitHub Actions — 태그 push 자동 릴리스 (Android APK + macOS ZIP), Pages 배포, 리졸버 헬스체크 cron |

### 공유 패키지 — `packages/shared`
타입/상수만 공유(로직 금지): `stream_resolver.dart`(리졸버 공통), `stream_resolution_result.dart`, `debug_logger.dart`(DebugLogger), `anywhere_shared.dart`.

## 2. 프로젝트 구조 (모노레포)

```
AnywhereTV/
├── anywhere_tv/          # 어디서나TV 앱 (macOS + Android, Flutter)
│   └── lib/
│       ├── models/       # channel / epg_program / user_state
│       ├── data/         # app_database.dart (Drift)
│       ├── repositories/ # channel_repository.dart (원격 JSON + 로컬 캐시)
│       ├── services/     # epg / background / tts / user_state / error_messages
│       ├── sources/      # hls_player_adapter.dart (media_kit)
│       └── ui/           # channel_list / player / epg_timeline / settings / debug_panel
├── channel_manager/      # Channel Manager (macOS 전용 편집기, Flutter)
│   └── lib/
│       ├── models/       # channel
│       ├── services/     # ai_assistant / ai_search / youtube_meta / health / validation /
│       │                 # diff / m3u / backup / logo / logo_cache / github / channel_store / player
│       ├── screens/      # main / add_channel / edit_channel / ai_channel_search / ai_assistant /
│       │                 # category_manager / diff / health_report / m3u_import / version_history /
│       │                 # test_play / settings
│       └── ui/           # debug_panel
├── packages/shared/      # 타입/상수/로거 공유
├── docs/                 # PRD · DESIGN · PLAN · ROADMAP · TODO · 랜딩(index.html)
├── .github/workflows/    # 릴리스 · Pages · 리졸버 헬스체크
└── build_and_run.sh      # 빌드 디스패처 (debug|release × ios|android|macos|cm|...)
```

## 3. 데이터 흐름

### 채널 목록 동기화
1. Channel Manager가 `channels_v{latest}.json`을 GitHub Gist에 저장 (SHA 기반 충돌 방지, 버전 자동 증가, 히스토리 포함)
2. 어디서나TV는 Gist 최신 JSON 다운로드 → 실패 시 로컬 캐시/assets 재생
3. `package:shared`의 `stream_resolver`가 리졸버 공통 로직을 공유 (중복 제거)

### 재생 파이프라인
```
Channel 목록 → 리졸버(stream_resolver) → HLS/YouTube/dash/audio URL
            → HlsPlayerAdapter(media_kit + libmpv) → PlayerScreen
            → 오류 시 3회 자동 재시도 / backupStreamUrl 폴백
```

### AI (ChannelManager)
- **어시스턴트**: 자연어 명령 → `AiAssistantService` generateContent → 수정된 JSON → Diff 미리보기 → 적용(Undo 가능)
- **검색/추천**: `AiSearchService` — Gemini web search(`google_search`) 기반.
  - 무료 티어 429/403 → **유튜브 검색 결과 페이지 파싱 폴백**(`searchYoutube` → `parseYoutubeResults`, ytInitialData 파싱, 후보 10개)
  - 사이트 URL 조사 탭은 폴백 불가(유료 플랜 필요 → E-MAN-AI-1005 안내)
- **모델 단일 소스**: `AiAssistantService.models = ['gemini-3.5-flash','gemini-3.1-flash-lite']` — 모든 AI 서비스가 공유

## 4. 리졸버

| 리졸버 | 대상 | 방식 |
|--------|------|------|
| InnerTube | 유튜브 라이브 | 공식 player API → HLS 변환 |
| YouTube Handle | `@채널명/live` | 라이브 페이지 → videoId 추출 → InnerTube |
| KBS | KBS1/2 | 랜딩 API → 스트림 URL |
| MBC | MBC | OnAir API (5개 후보 순회) |
| SBS | SBS | play-api → mediaurl 추출 |

> 소스 타입: HLS / YouTube / **dash / audio** (v2.4 확장)

## 5. 오류 처리 & 로깅

- 모든 I/O/API `try-catch`, 에러코드 래핑: `E-{PLATFORM}-{CATEGORY}-{NUM4}` (`IOS/AND/MAC/WEB/CHR/FIR/SAF/SRV/COM/MONO/E2E`)
- 사용자 메시지는 `error_message_ko.json` 분리
- 로거: `DebugLogger`(shared) — `[INFO]`/`[ERROR]`/`[PERF]`/`[CACHE]` 레벨, DebugPanel 표시 (macOS 뒤도, 별도 패널)
- 대표 코드: `E-MAN-AI-1005`(Gemini 할당량), `E-MAN-AUTH-1001`(인증), `E-MAN-AI-1002`(AI 실패), `E-MAN-BACK-1001`(백업), `E-MAN-M3U-1001`(M3U), `E-MAN-URL-1005`(URL 조사)

## 6. 성능/캐시 예산

- Cold Start ≤2.0s(Android) / ≤1.5s(macOS) · LCP ≤2.5s
- 외부 이미지 로고 캐시: 로컬 파일 캐시(`LogoCacheService`)
- EPG 캐시 TTL 6시간 / 시청 기록 최대 20 (Drift)
- 라이브 대시보드 5분 자동 검사(설정 토글)
- AI 호출은 LLM 비용·429 방지 위해 호출 최소화 (캐시 도입 후보)
