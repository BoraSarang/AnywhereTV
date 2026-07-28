# 어디서나 TV — 구현 계획 (PLAN)

> 버전: 1.0.0 (Phase 1)
> 최종 업데이트: 2026-07-28

## 개요

Flutter 기반 크로스플랫폼 실시간 채널 뷰어 앱. Phase 1은 8개 채널 (KBS1/2, MBC, SBS, EBS1/2, YTN, 연합뉴스TV) 지원.

## 완료된 단계

- [x] **T-01**: Flutter 프로젝트 생성 및 의존성 설치
- [x] **T-02**: Channel/UserState 모델 구현
- [x] **T-03**: ChannelRepository + 원격 JSON 로더
- [x] **T-04**: UserStateService (SharedPreferences)
- [x] **T-05**: HLS 플레이어 어댑터 (media_kit)
- [x] **T-06**: YouTube 플레이어 어댑터 (youtube_player_flutter)
- [x] **T-07**: PlayerScreen (채널 전환, 오버레이, 스와이프)
- [x] **T-08**: ChannelListScreen (즐겨찾기 관리)
- [x] **T-09**: SettingsScreen (해상도 설정)
- [x] **T-10**: main.dart (테마, 라우팅, 초기화)
- [x] **T-11**: macOS 빌드 성공
- [x] **T-12**: 앱 아이콘 플랫폼별 적용

## 남은 단계

- [ ] **T-13**: 스트림 URL 리졸버 구현 (KBS, SBS, MBC)
- [ ] **T-14**: channels.json 호스팅 및 적용
- [ ] **T-15**: Android 빌드 환경 구성 및 검증
- [ ] **T-16**: iOS 빌드 환경 구성 및 검증
- [ ] **T-17**: 실제 채널 스트림 URL 검증 및 channels.json 업데이트

## 테스트 계획

- [ ] **TC-01**: macOS 앱 실행 및 EBS1/EBS2 정상 재생 확인
- [ ] **TC-02**: YTN/연합뉴스TV 유튜브 라이브 재생 확인
- [ ] **TC-03**: 좌우 스와이프 채널 전환 동작 확인
- [ ] **TC-04**: 즐겨찾기 추가/제거 동작 확인
- [ ] **TC-05**: 마지막 시청 채널 복원 확인
- [ ] **TC-06**: 해상도 설정 저장/복원 확인
- [ ] **TC-07**: 원격 JSON 채널 목록 갱신 확인

## 롤백 계획

- 각 단계 완료 시 `git commit`으로 스냅샷
- 문제 발생 시 이전 커밋으로 `git revert`
