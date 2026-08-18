# 세션 로그 — 2026-08-18 (macos) — v2.4 브랜드 교체

## 1. 무엇을
- T-133: 브랜드 ID `okstart` → `com.borasarang.*` 전면 교체 (소스 15개 파일 + Android 패키지 이동 + git 히스토리 재작성 + GitHub 저장소 재생성)
- T-132 진행: AI 검색 429 대응 — Gemini web search(유료 필요) 실패 시 유튜브 검색 결과 파싱 폴백으로 대체. 호출부 2곳 레코드 반환 처리. E-MAN-AI-1005 추가.
- AI 모델 단일화: `AiAssistantService.models` = ['gemini-3.5-flash', 'gemini-3.1-flash-lite'] 모든 AI 서비스 공유
- 채널 추천 화면 멈춤 수정: TabBarView 고정 높이 64px (Column 내 unbounded height)
- build_and_run.sh에 `cm` 플랫폼 추가 + channel_manager/scripts/build-macos.sh 신설

## 2. 플랫폼
- macOS (channel_manager + anywhere_tv), git/리모트

## 3. 빌드 결과
- `./build_and_run.sh debug cm` ✅ (analyze error 0, 테스트 14건 통과)
- `./build_and_run.sh debug macos` + `release macos` (dist 재빌드) ✅
- git filter-repo: 전체 히스토리 재작성 완료, `-S okstart` 0건, 커밋 38개 유지
- GitHub: BoraSarang/AnywhereTV 삭제 → PUBLIC로 재생성 → force push (6cc0092)
- 데이터 이전: com.okstart.channelManager → com.borasarang.channelManager (backups/logos), anywheretv 앱 데이터 이전 ✅

## 4. 남은 TODO
- T-132: TC-MAN-012~015 실사용 테스트 (AI 로고 검색, 자연어 추천, 사이트 조사, dash/audio)

## 5. 다음 에이전트 전달
- AI 검색은 유튜브 폴백으로 무료 동작. 사이트 조사 탭은 여전히 유료 플랜 필요 (429 → E-MAN-AI-1005 안내)
- 구 컨테이너 com.okstart.* 는 백업으로 유지 (사용자 확인 후 삭제 가능)
- 기존 분석 경고 2건 (add_channel_screen `_playing`, test_play_screen `_streamUrl`) — 무해
- backup-pre-brand-filter 브랜치 존재 (필터 전 백업)

## 6. 문서 업데이트
- docs/TODO.md (v2.4 섹션), docs/plans/PLAN_v2.4_channel_manager.md (기존), AGENTS.local.md (번들 ID 자동 치환됨)

## 7. 오프라인 큐
- 해당 없음 (오프라인 큐 기능 없음 — Gist 기반 동기화)

## 8. E2E/k6
- 해당 없음 (macOS 데스크톱 앱)
