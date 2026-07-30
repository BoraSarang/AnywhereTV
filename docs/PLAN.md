# 어디서나 TV — 구현 계획 (PLAN)

> 버전: 1.2.0
> 최종 업데이트: 2026-07-30

## 개요

Flutter + media_kit 기반 크로스플랫폼 (Android + macOS) 한국 실시간 TV 뷰어.
방송사 공식 스트림 + YouTube InnerTube API → HLS로 27개 채널 제공.

## 완료

- [x] Android + macOS 빌드/배포 파이프라인
- [x] 27개 채널 설정 (v6, Gist 원격 업데이트)
- [x] HLS + YouTube InnerTube 리졸버 (KBS/SBS/MBC/youtube/youtube_handle)
- [x] 즐겨찾기 + 카테고리 정렬 + 마지막 채널 복원
- [x] 해상도 선택 (360p~1080p)
- [x] DebugLogger + DebugOverlay 디버그 패널
- [x] Android 서명 APK (CI + 로컬)
- [x] macOS 싱글 인스턴스 가드
- [x] INTERNET 퍼미션 (릴리즈 빌드)
- [x] 앱 생명주기 처리 (백그라운드 → 포그라운드 복원)
- [x] YouTube videoId 우선 처리 (handle 중복 문제 해결)

## v1.2.0 진행중

자세한 계획: `docs/ROADMAP.md`

- [ ] EPG (전자 프로그램 가이드) — 현재 방영중 표시
- [ ] 백그라운드 재생 (Android Foreground Service)
- [ ] 자동 재연결 (스트림 끊김 시 retry)
- [ ] 채널 검색

## 빌드 명령어

```bash
./build_and_run.sh release android   # Android APK
./build_and_run.sh release macos     # macOS .app
./build_and_run.sh debug android     # 디버그 APK
```

## 테스트 방법

1. Android: `./build_and_run.sh release android` → `adb install -r -d dist/*.apk`
2. macOS: `build_and_run.sh release macos` → 자동 실행
3. 각 채널 전환, 해상도 변경, 앱 재시작 후 마지막 채널 복원 확인
