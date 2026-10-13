# 멍냥노트 🐶🐱

반려동물의 일상과 케어 기록을 한곳에 모으는 **SwiftUI 기반 iOS 앱**입니다. 오늘 할 일을 체크하고, 식사·산책·증상·병원 기록과 사진을 남겨 한 달의 관리 흐름을 돌아볼 수 있습니다.

**현재 상태: TestFlight 준비 중**

## 주요 기능

- **반려동물 프로필**: 이름, 종류, 품종, 나이 문구, 특징, 사진 관리 및 여러 마리 프로필 추가·선택·수정·삭제
- **오늘의 케어**: 체크 항목 관리, 완료 표시, 날짜 변경 확인 시 완료 상태 초기화, 항목별 알림
- **하루 한 줄 메모**: 짧은 메모 저장·수정·고정. 현재는 날짜별 누적 일기가 아닌 공용 메모입니다.
- **생활 기록**: 식사·산책·증상·병원 등 유형별 기록, 날짜·제목·메모·사진 입력, 기록 조회·삭제
- **영양제**: 급여량·시간·메모 관리, 완료 체크, 알림 권한을 이용한 반복 로컬 알림
- **몸무게**: 날짜별 체중·메모 저장 및 케어 기록 연동
- **사진 앨범**: 선택한 반려동물의 기록에 첨부된 사진 모아보기와 상세 보기
- **월간 리포트**: 월별 기록 건수, 산책 시간 합계, 사진 수, 몸무게 변화 요약
- **펫상식**: 앱에 포함된 강아지·고양이 상식 콘텐츠
- **관리**: 테마 선택, JSON 백업·복원, 데이터 초기화, 온보딩 안내

## 화면 구성

| 화면 | 역할 |
| --- | --- |
| 홈 | 반려동물 선택, 오늘의 케어, 메모, 산책 타이머 및 관리 화면 진입 |
| 기록 | 날짜별 케어 기록 확인, 기록 추가·삭제 |
| 영양제 | 급여 항목과 완료 상태, 시간 알림 관리 |
| 펫상식 | 강아지·고양이 상식 확인 |
| 관리 화면 | 프로필, 사진 앨범, 월간 리포트, 테마, 데이터 관리 |

## 스크린샷

사용자가 제작한 App Store 홍보용 이미지로 실제 앱 화면을 소개합니다. 현재는 **TestFlight 준비 중**입니다.

| 홈 | 기록 | 월간 리포트 |
| --- | --- | --- |
| ![멍냥노트 홈](screenshots/01_home_promo.png) | ![멍냥노트 기록](screenshots/02_records_promo.png) | ![멍냥노트 월간 리포트](screenshots/03_report_promo.png) |

| 영양제 | 펫상식 |
| --- | --- |
| ![멍냥노트 영양제](screenshots/04_supplement_promo.png) | ![멍냥노트 펫상식](screenshots/05_tips_promo.png) |

이미지별 설명은 [스크린샷 안내](screenshots/README.md)를 참고하세요.

## 기술 스택

| 기술 | 사용 목적 |
| --- | --- |
| Swift / SwiftUI | 화면 구성, 상태 관리, 탭 및 내비게이션 |
| Foundation / Codable | 모델 정의, JSON 인코딩·디코딩, 날짜 처리 |
| UserDefaults | 프로필·기록·설정의 기기 내 저장 |
| PhotosUI / PhotosPicker | 프로필 및 기록 사진 선택 |
| UIKit | 이미지 크기 조절 및 JPEG 변환 |
| UserNotifications | 케어·영양제 로컬 알림 |

## 데이터 저장 방식

별도의 서버나 로그인 없이 앱이 사용하는 기기 내 UserDefaults에 저장합니다. 프로필·케어·영양제·몸무게 모델은 Codable로 JSON Data로 변환하고, 메모·테마 등의 단순 값은 직접 저장합니다. 사진은 크기를 줄인 JPEG Data로 모델에 포함합니다.

기록은 `petID`로 반려동물과 연결하며 화면에서 선택한 프로필에 맞춰 조회합니다. 이전 형식의 `petID` 없는 데이터는 첫 번째 기본 프로필에 표시합니다. 메모와 테마 등 일부 값은 앱 전체에서 공유합니다. 자동 클라우드 동기화는 구현되어 있지 않으며, 데이터 관리 화면에서 JSON 파일로 직접 백업·복원할 수 있습니다.

## 실행 환경 및 빌드

- macOS와 Xcode, iOS Simulator
- 앱 Deployment Target: **iOS 17.0 이상**
- 프로젝트 Swift 언어 설정: **Swift 5**
- 문서 확인에 사용한 개발 도구: **Xcode 26.6** (최소 지원 Xcode 버전을 의미하지 않습니다.)

저장소 루트에서 `DangDangNote.xcodeproj`를 Xcode로 열고 `DangDangNote` 스킴과 iOS 17 이상 Simulator를 선택한 뒤 Run을 실행합니다. 별도의 서버 설정은 필요하지 않습니다.

서명 없이 Simulator용 빌드만 확인하려면:

```sh
xcodebuild -project DangDangNote.xcodeproj \
  -scheme DangDangNote -configuration Debug \
  -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath /tmp/DangDangNote-PortfolioBuild \
  CODE_SIGNING_ALLOWED=NO build
```

실기기 실행 및 배포에는 유효한 개발자 서명 환경이 필요합니다. 현재 Bundle ID와 Signing 설정을 기준으로 확인해야 합니다. 이 문서 작업에서는 해당 설정을 변경하지 않았습니다.

## 프로젝트 살펴보기

- [설계와 구현 상세](docs/portfolio.md)
- [문제 대응과 구현 근거](docs/troubleshooting.md)
- [스크린샷 등록 가이드](screenshots/README.md)
- [샘플 이미지 출처](docs/sample-image-provenance.md)

구현 설명은 현재 소스 기준입니다. 테스트 타깃에는 예제 테스트가 있으며, 기능 검증이 완비된 상태로 소개하지 않습니다.
