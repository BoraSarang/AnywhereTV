# 어디서나 TV — AGENTS.local.md

> 이 파일은 이 프로젝트에만 적용되는 에이전트 규칙입니다.
> 공통 규칙은 `~/.config/opencode/AGENTS.md`를 우선 따릅니다.

---

## 프로젝트 구조

```
anywhere_tv/            Flutter 프로젝트
├── lib/                Dart 소스 코드
├── macos/              macOS 네이티브 설정
├── android/            Android 네이티브 설정
├── ios/                iOS 네이티브 설정
scripts/                플랫폼별 빌드 스크립트
├── build-macos.sh      macOS 빌드
├── build-ios.sh        iOS 빌드 (미구현)
├── build-android.sh    Android 빌드 (미구현)
├── build-web.sh        Web 빌드 (미구현)
docs/                   문서 (PRD, DESIGN, PLAN, TODO)
channels.json           원격 채널 설정 파일 샘플
build_and_run.sh        빌드 디스패처 (필수 사용)
CHANGELOG.md            변경 이력
```

---

## 플랫폼 설정

| 항목 | 값 |
|------|-----|
| 번들 ID (macOS/iOS) | `com.borasarang.anywheretv` |
| 패키지명 (Android) | `com.borasarang.anywheretv` |
| Flutter 프로젝트 | `anywhere_tv/` |
| macOS 배포 경로 | `~/Applications/AnywhereTV.app` |
| Android APK 경로 | `~/Applications/apk/` |
| iOS 앱 경로 | `~/Applications/ios/` |

---

## 빌드 및 실행 (필수)

코드 수정 후 반드시 `./build_and_run.sh`를 실행하여 검증한다.
직접 `flutter build`, `flutter run`, `open` 등을 호출하지 않는다.

### 사용법
```bash
./build_and_run.sh                                       # macOS debug
./build_and_run.sh debug macos                           # macOS debug
./build_and_run.sh release macos                         # macOS release
./build_and_run.sh debug ios --device="iPhone 15 Pro"    # iOS (미구현)
./build_and_run.sh debug android --device="Pixel_8"      # Android (미구현)
./build_and_run.sh debug web                             # Web (미구현)
./build_and_run.sh debug all                             # 전체 플랫폼
./build_and_run.sh clean                                 # macOS 산출물 정리
```

---

## 코드 수정 원칙

1. `flutter analyze` 통과 필수 (0 issues)
2. 새 기능 추가 시 `docs/TODO.md` 업데이트
3. `build_and_run.sh` 실행하여 빌드/실행 검증
4. 버그 발견 시 `bd create` 로 등록
5. 공통 코드 수정 시 `scripts/build-macos.sh`로 macOS 검증 우선

---

## 환경

- Flutter 3.44.6 (stable)
- Dart 3.12.2
- macOS 26.5.2 (Apple Silicon)
- 타겟: macOS 디버그 우선 (Android/iOS는 SDK 환경 필요)
