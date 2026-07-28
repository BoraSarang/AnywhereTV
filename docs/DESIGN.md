# 어디서나 TV — 기술 설계 (DESIGN)

> 버전: 1.0.0 (Phase 1)
> 최종 업데이트: 2026-07-28

## 1. 기술 스택

| 항목 | 선택 |
|------|------|
| 프레임워크 | Flutter 3.44.6 (Dart 3.12.2) |
| HLS 재생 | media_kit 1.2.6 |
| 유튜브 재생 | youtube_player_flutter 10.0.1 |
| 로컬 저장 | shared_preferences 2.5.5 |
| HTTP | http 1.6.0 |
| 이미지 캐싱 | cached_network_image 3.4.1 |

## 2. 프로젝트 구조

```
lib/
├── main.dart                          # 앱 진입점, 테마, 라우팅
├── models/
│   ├── channel.dart                   # Channel 데이터 모델
│   └── user_state.dart                # UserState (즐겨찾기, 설정)
├── repositories/
│   └── channel_repository.dart        # 채널 목록 관리 (원격 JSON + 로컬 캐시)
├── services/
│   └── user_state_service.dart        # SharedPreferences 래퍼
├── sources/
│   ├── hls_player_adapter.dart        # media_kit 래퍼
│   └── youtube_player_adapter.dart    # youtube_player_flutter 래퍼
└── ui/
    ├── player_screen.dart             # 메인 재생 화면
    ├── channel_list_screen.dart       # 채널 목록/즐겨찾기 관리
    └── settings_screen.dart           # 설정 화면
```

## 3. 아키텍처

### 데이터 흐름

```
[원격 channels.json] → [ChannelRepository] → [PlayerScreen]
                            ↓                      ↓
                      [SharedPreferences]    [Player Adapter]
                          (캐시)           (HLS / YouTube)
```

### 채널 소스 어댑터 패턴

각 채널의 `sourceType`에 따라 플레이어를 자동 전환:
- `hls` → `HlsPlayerAdapter` (media_kit)
- `youtube_live` → `YoutubePlayerAdapter` (youtube_player_flutter)

### URL 리졸버

동적 URL이 필요한 채널(KBS, SBS, MBC)은 채널별 리졸버를 통해 실행 시점에 스트림 URL 획득:
- **KBS**: `cfpwwwapi.kbs.co.kr` API → CloudFront Signed URL
- **SBS**: `apis.sbs.co.kr` API → 토큰 포함 HLS URL
- **MBC**: iMBC 온에어 API (추가 조사 필요)

## 4. 채널 설정 파일 구조

```json
{
  "version": "2026-07-28",
  "channels": [
    {
      "id": "kbs1",
      "name": "KBS1",
      "logoUrl": "https://...",
      "streamUrl": null,
      "sourceType": "hls",
      "category": "지상파",
      "resolver": "kbs",
      "resolverData": {"channelCode": "11"}
    }
  ]
}
```

## 5. 상태 관리

- 앱 상태는 `SharedPreferences`에 저장 (간단한 키-값)
- `UserState` 모델: 즐겨찾기, 마지막 채널, 해상도, 볼륨
- 채널 리스트는 빌트인 → 로컬 캐시 → 원격 JSON 순으로 초기화

## 6. UI 원칙

- 버튼 최소 56pt (어르신 친화)
- 고대비 다크 테마 (`#1A1A2E` 배경, 흰색 텍스트)
- 메뉴 depth 최대 2단계
- 앱 실행 → 스플래시 없이 바로 마지막 채널 재생
