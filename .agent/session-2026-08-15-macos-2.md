# 세션 로그 — 2026-08-15 (macos) 2차

## 1. 무엇을
- T-100 완료 후 P4 (T-114~T-117) 전부 완료, T-111 시작 전

## 2. 플랫폼
- macOS + Android (T-114~117 모두), iOS는 지역화만

## 3. 빌드 결과
- flutter analyze: 7 issues (기존 이슈만, 신규 0건)
- `./build_and_run.sh debug macos` ✅
- `./build_and_run.sh debug android` ✅
- TTS: flutter_tts 4.2.5 추가 (macOS/Android 빌드 정상)

## 4. 남은 TODO
- T-111 Android TV D-pad → T-112 PiP → T-113 채널 즉시 전환 (P3)
- 이후 P1 (T-105~107), P2 (T-108~110), P0 (T-101~104)

## 5. 다음 에이전트 전달
- player_screen.dart에 `_setupEpgAlerts`/`_startEpgPolling` 추가됨 — 방송 시작 5분 전 SnackBar
- 채널 목록: 즐겨찾기 섹션(드래그 재정렬, ReorderableListView + onReorderItem) + 최근 시청 섹션
- TTS: `TtsService` 싱글턴 (ko-KR, rate 0.45), PlayerScreen._speakChannel에서 채널명+프로그램명
- epgUrl은 아직 채널 데이터에 없음 — epgUrl 가진 채널부터 알림 동작 (T-105에서 데이터 추가 예정)
- 즐겨찾기 순서: 저장 순서 존중으로 변경됨 (기존 카테고리 정렬 제거) — 사용자 순서 유지

## 6. 문서 업데이트
- docs/TODO.md (T-114~117 완료), CHANGELOG.md (v2.1.0)

## 7. 오프라인 큐 상태
- 해당 없음

## 8. E2E/k6
- 해당 없음