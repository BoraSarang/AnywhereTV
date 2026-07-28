# 어디서나 TV — 작업 추적 (TODO)

> 최종 업데이트: 2026-07-28

## 진행 중 (Phase 1)

| 작업 | 상태 | 우선순위 |
|------|------|---------|
| DebugPanel v1.6 표준 준수 | completed | high |
| 빌드 디스패처 (scripts/*.sh) | completed | high |
| EBS1/EBS2 실제 재생 검증 | pending | high |
| KBS/SBS/MBC 리졸버 디버깅 | pending | high |
| YTN YouTube 라이브 videoId 조회 | pending | high |
| 연합뉴스TV 실제 재생 검증 | pending | high |

## 세부 작업

- [x] Flutter 프로젝트 생성
- [x] 의존성 설치
- [x] Channel 모델
- [x] UserState 모델 및 서비스
- [x] ChannelRepository (빌트인 → 캐시 → 원격)
- [x] HlsPlayerAdapter (media_kit)
- [x] YoutubePlayerAdapter
- [x] PlayerScreen (스와이프/오버레이/내비게이션)
- [x] ChannelListScreen
- [x] SettingsScreen
- [x] main.dart (MediaKit, 테마, 라우팅)
- [x] macOS 빌드 성공
- [x] flutter analyze 통과 (0 issues)
- [x] 앱 아이콘
- [x] 번들 ID 통일 (com.okstart.anywheretv)
- [x] DebugLogger (platform, maskSecrets, formatForAgent)
- [x] DebugPanel (플랫폼 필터, 320px 리사이즈, 1.5s 자동 재개)
- [x] Cmd+Shift+D 키보드 단축키
- [x] release 모드 DebugOverlay 제거
- [x] build_and_run.sh 디스패처 (scripts/build-*.sh 분리)
- [x] AGENTS.local.md 업데이트
- [x] CHANGELOG.md 업데이트

- [ ] EBS1/EBS2 실제 HLS 재생 검증
- [ ] KBS 스트림 리졸버 (cfpwwwapi.kbs.co.kr)
- [ ] SBS 스트림 리졸버 (apis.sbs.co.kr)
- [ ] MBC 스트림 리졸버 (iMBC onair)
- [ ] YTN YouTube 라이브 videoId 조회
- [ ] 연합뉴스TV YouTube 재생 검증
- [ ] Android SDK 설치 및 APK 빌드
- [ ] iOS 빌드 확인
- [ ] 채널 스트림 URL 전체 검증
