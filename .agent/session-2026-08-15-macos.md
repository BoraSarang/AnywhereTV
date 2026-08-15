# 세션 로그 — 2026-08-15 (macos)

## 1. 무엇을
- T-100: 앱 표시 이름 시스템 언어 자동 지역화 완료

## 2. 플랫폼
- macOS (AnywhereTV + ChannelManager), Android, iOS

## 3. 빌드 결과
- `./build_and_run.sh debug macos` ✅ AnywhereTV.app 배포
- `./build_and_run.sh debug android` ✅ APK 배포
- `flutter build macos --debug` (channel_manager) ✅
- pbxproj plutil lint + xcodebuild -list 통과
- flutter analyze: 기존 이슈만 (신규 0건, Dart 코드 미변경)

## 4. 남은 TODO
- T-114 TTS, T-115 즐겨찾기 재정렬, T-116 시청 기록, T-117 방송 알림 (P4)
- 이후 T-111~113 (P3), T-105~107 (P1), T-108~110 (P2), T-101~104 (P0)

## 5. 다음 에이전트 전달
- InfoPlist.strings는 UTF-16 LE로 컴파일됨 (정상, iconv로 확인)
- macOS VariantGroup에는 `path = Runner` 필수 (누락 시 "Build input file cannot be found" 에러 — 경험함)
- channel_manager는 루트 build_and_run.sh 미지원 → 직접 `flutter build macos --debug` 필요
- 검증 기준: mdls kMDItemDisplayName (Finder 표시 이름), 시스템 언어 ko-KR → 한국어 확인됨

## 6. 문서 업데이트
- docs/plans/PLAN_v2.0_proposal.md (생성), docs/TODO.md (T-100 완료), CHANGELOG.md (v2.0.0)

## 7. 오프라인 큐 상태
- 해당 없음 (네이티브 리소스 작업)

## 8. E2E/k6
- 해당 없음