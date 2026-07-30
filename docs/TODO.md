# 어디서나 TV — 작업 추적 (TODO)

> 최종 업데이트: 2026-07-30
> 현재 버전: v1.2.0

## v1.2.0 — "EPG + 안정성"

| 작업 | 상태 | 예상 시간 |
|------|------|----------|
| EPG 데이터 모델 (`EpgProgram`) + `epgUrl` 필드 | pending | 30m |
| XMLTV/JSON EPG 파서 | pending | 1h |
| EPG UI — 오버레이 프로그램명 | pending | 30m |
| EPG UI — 채널 리스트 프로그램명 | pending | 30m |
| 백그라운드 재생 (Android) | pending | 1h |
| 자동 재연결 (Player error retry) | pending | 30m |
| 채널 검색 | pending | 30m |
| 빌드 + 테스트 + 릴리즈 | pending | 30m |

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
