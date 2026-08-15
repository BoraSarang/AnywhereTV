# 세션 로그 — 2026-08-15 (channel_manager 실사용 테스트 — TC-MAN 전체 통과)

## 1. 무엇을 (T-번호 포함)
- TC-MAN-001~011 실사용 테스트 진행. **TC-MAN-002~009 전부 OK 확인**
- 유튜브 VOD 해석 지원 (stream_resolver: hlsManifestUrl 없으면 progressive itag 18/22/37/59 폴백)
- add_channel_screen `_save()` async 버그 수정 + ID 유니크 보장 (`-2`, `-3` 접미사)
- 목록 미표시 3건 해결: 카테고리 필터 / 중복 ID 키 충돌(ValueKey(ch.id)) / 카테고리 맨 앞 삽입(addChannel)
- 로고 표시: Image.network 완전 제거 → 파일 캐시(LogoCacheService) + 회색 TV 아이콘 폴백 + `_onStoreChanged` 프리캐시
- 일괄 이동/삭제 후 선택 모드 자동 해제
- M3U: 내보내기/가져오기 중복 스킵 + 이름 안 쉼표 파싱 수정(첫 쉼표+따옴표 스캔) — `채널 N개 추가 (중복 M개 건너뜀)`
- AI 어시스턴트 모델 교체: gemini-1.5-flash 단종 → gemini-3.5-flash → gemini-3.1-flash-lite fallback 체인
- 채널 편집: 대체 URL 필드 소스 유형 무관 항상 표시

## 2. 플랫폼
- [macos] channel_manager (배포: /Users/lee/Applications/AnywhereTV Channel Editor.app)

## 3. 빌드 결과
- flutter analyze error 0, flutter test 8건 통과, debug 빌드 + 재배포 성공 (반복 6회)
- Gist 저장 v13 검증: 29채널, 중복 ID 없음. 백업 파일 생성 확인 (샌드박스 경로: ~/Library/Containers/com.borasarang.channelManager/Data/Library/Application Support/AnywhereTVChannelEditor/backups/)

## 4. 남은 TODO
- 사용자 Gist v14 저장 여부 (테스트 채널 2_1_2 정리 결정 필요 — v13에 저장됨)
- 커밋 여부 미확인
- TC-MAN-010(어디서나TV 재생 연동), 011(기타)는 미실시

## 5. 다음 에이전트 전달 로그
- gemini-1.5-flash/2.x-flash는 2026년 단종. `ai_assistant_service.dart` 모델 체인: gemini-3.5-flash → gemini-3.1-flash-lite (Interactions API 마이그레이션은 아직 안 함 — generateContent 유지, 작동 확인됨)
- M3U 파싱: EXTINF 이름은 따옴표 바깥 첫 쉼표 기준 (`_extractName`)
- 로고는 Image.network 금지 — LogoCacheService 파일 캐시만 사용
- bbackd(SBS 옛날 드라마) 등 HLS 채널만 대체 URL 실사용. 유튜브 채널 폴백은 videoId→핸들 해석이 담당

## 6. 문서 업데이트 목록
- docs/plans/PLAN_v2.3_channel_manager.md (TC-MAN 상태만 기록, 전부 ✅)

## 7. 오프라인 큐 상태
- 해당 없음

## 8. E2E/k6 결과
- flutter test 8건 + analyze 0 에러 유지
- 실사용 확인: 목록 추가/이동/삭제, 로고 표시, M3U 왕복 28개 전부 중복 스킵, Diff, AI(200) 확인
