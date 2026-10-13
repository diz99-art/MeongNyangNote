# 멍냥노트 🐶🐱

**여러 반려동물의 케어와 생활 기록을 한곳에 모으는 SwiftUI iOS 앱**

![Swift 5 · SwiftUI · iOS 17+ · Xcode · Portfolio · Local Storage](docs/assets/stack-badges.svg)

> **TestFlight 준비 중** · iPhone / Portrait · 서버 없이 로컬 저장
>
> 포트폴리오 정리를 진행했으며, TestFlight 업로드는 잠시 중단한 상태입니다.

[구현 상세](docs/portfolio.md) · [문제 해결 과정](docs/troubleshooting.md) · [스크린샷 안내](screenshots/README.md)

## 프로젝트 개요

식사·산책·영양제처럼 매일 챙길 일과 증상·병원 방문 같은 생활 기록을 연결합니다. 보호자는 반려동물을 선택하고, 오늘의 케어를 체크한 뒤 사진과 월간 리포트로 관리 흐름을 돌아볼 수 있습니다. 회원가입과 서버 설정 없이 기기에서 사용할 수 있도록 구성했습니다.

## 주요 기능

| 영역 | 구현된 기능 |
| --- | --- |
| 프로필 | 여러 마리 등록·선택·수정·삭제, 이름·종류·품종·나이 문구·특징·사진 |
| 홈 | 오늘의 케어 체크리스트, 항목별 알림, 한 줄 메모 저장·수정·고정, 산책 타이머 |
| 생활 기록 | 식사·산책·증상·병원 등 유형별 입력, 날짜별 조회·삭제, 사진 첨부 |
| 영양제·체중 | 급여량·시간·완료 체크·반복 알림, 날짜별 체중 기록과 케어 기록 연동 |
| 모아보기 | 기록 사진 앨범, 월별 건수·산책 시간·체중 변화 리포트, 강아지·고양이 펫상식 |
| 관리 | 첫 실행 온보딩, 테마, JSON 백업·복원·초기화, 스크린샷용 샘플 데이터 |

한 줄 메모는 날짜별 누적 일기가 아닌 **앱 공용 메모**입니다. 사진 앨범은 기록에 첨부한 사진을 모으며, 리포트는 저장된 기록을 집계합니다.

## 스크린샷

실제 화면을 담은 사용자 제작 App Store 홍보용 이미지입니다. 이름·날짜·기록은 화면 예시입니다.

| 홈 | 기록 | 월간 리포트 |
| --- | --- | --- |
| ![멍냥노트 홈](screenshots/01_home_promo.png) | ![멍냥노트 기록](screenshots/02_records_promo.png) | ![멍냥노트 월간 리포트](screenshots/03_report_promo.png) |
| 오늘의 케어와 한 줄 메모 | 달력으로 확인하는 생활 기록 | 기록 건수·산책 시간·체중 변화 |

| 영양제 | 펫상식 |
| --- | --- |
| ![멍냥노트 영양제](screenshots/04_supplement_promo.png) | ![멍냥노트 펫상식](screenshots/05_tips_promo.png) |
| 급여 체크와 시간 알림 | 강아지·고양이 생활 상식 |

## 기술 스택

| 기술 | 활용 |
| --- | --- |
| Swift / SwiftUI | TabView·NavigationStack, State·StateObject·EnvironmentObject, 공통 테마 |
| Foundation / Codable / UserDefaults | 모델 직렬화, 로컬 저장, 날짜별 필터링 |
| PhotosUI / PhotosPicker / UIKit | 사진 선택, 이미지 표시와 일부 경로의 JPEG 축소 |
| UserNotifications | 케어·영양제 로컬 알림과 권한 처리 |

## 프로젝트 구조

```text
DangDangNote.xcodeproj/         # Xcode 프로젝트
DangDangNote/
├─ DangDangNoteApp.swift        # 앱 진입점
├─ ContentView.swift            # 온보딩 분기·4개 탭·테마
├─ HomeView.swift               # 체크리스트·메모·산책
├─ HistoryView.swift            # 날짜별 기록 조회
├─ AddRecordView.swift          # 기록 모델·입력·저장 헬퍼
├─ PetProfileStore.swift        # 프로필 목록·선택 상태
├─ PetManagementView.swift      # 여러 마리 관리
├─ SupplementCheckView.swift    # 영양제·알림
├─ WeightRecordView.swift       # 체중 기록
├─ PhotoAlbumView.swift         # 기록 사진 모아보기
├─ MonthlyReportView.swift      # 월별 집계
├─ PetTipsView.swift            # 내장 상식 콘텐츠
├─ DataManagementView.swift     # 백업·복원·샘플 데이터
├─ OnboardingView.swift         # 첫 사용 안내
├─ Info.plist                   # 명시적 앱 설정
└─ LaunchScreen.storyboard      # 시스템 시작 화면
DangDangNoteTests/              # 예제 테스트 타깃
docs/                         # 구현 상세·문제 대응·이미지 출처
screenshots/                  # 홍보 이미지 5장
```

주요 파일을 추린 구조입니다. 화면별 파일에 모델과 저장 헬퍼가 함께 정의된 부분도 있습니다.

## 핵심 구현 포인트

- **탭과 초기 진입**: 홈·기록·영양제·펫상식의 4개 탭에 NavigationStack을 두고, AppStorage 값으로 첫 실행 온보딩을 분기합니다.
- **여러 마리와 데이터 호환**: PetProfileStore가 선택 상태를 공유하고, `petID`로 기록을 구분합니다. ID 없는 이전 데이터는 첫 번째 기본 프로필에서 조회합니다.
- **기기 기능 연결**: PhotosPicker로 사진을 첨부하고, UserNotifications 권한 결과에 맞춰 영양제 알림 상태를 처리합니다.
- **집계와 백업**: 월·반려동물 기준으로 기록을 집계하며, JSON 파일 생성·공유와 복원을 제공합니다.
- **재현 가능한 화면 준비**: SampleDataSeeder가 프로필·기록·사진 예시를 구성하고, 샘플 적용 전 저장값을 스냅샷으로 보존합니다.

구현 흐름과 선택의 장단점은 [상세 포트폴리오](docs/portfolio.md)에 정리했습니다.

## 데이터 저장 방식

주요 모델은 Codable로 JSON Data로 변환해 UserDefaults에 저장합니다. 메모·테마 등 단순 값은 직접 저장하며, 사진 Data는 모델에 포함합니다. `petID`로 조회 범위를 구분하지만 메모·테마는 공용입니다.

자동 클라우드 동기화는 없으며 기기 이동 시 JSON 백업·복원을 사용합니다. 배열 전체와 사진을 UserDefaults에 저장하는 현재 방식은 작은 로컬 앱을 구현하기 간단하지만, 데이터 증가 시 저장 크기와 성능 검증이 필요합니다. 모든 사진 입력 경로가 동일하게 압축되는 것은 아닙니다.

## 실행 방법

1. macOS의 Xcode에서 `DangDangNote.xcodeproj`를 엽니다.
2. `DangDangNote` 스킴과 iOS 17 이상 iPhone Simulator를 선택합니다.
3. Run으로 실행하고 첫 사용 안내를 마친 뒤 프로필과 기록을 입력합니다.

프로젝트 Swift 언어 설정은 Swift 5이며, 이전 빌드 검증 환경은 Xcode 26.6입니다. 서명 없이 Simulator 빌드를 확인하려면:

```sh
xcodebuild -project DangDangNote.xcodeproj \
  -scheme DangDangNote -configuration Debug \
  -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath /tmp/DangDangNote-PortfolioBuild \
  CODE_SIGNING_ALLOWED=NO build
```

실기기 실행과 배포에는 별도의 유효한 서명·계정 환경이 필요합니다.

## 개발 과정에서 다룬 문제

첫 실행 진입 구조, 이전 데이터 호환, 이미지 로딩 실패, 알림 권한 거부, 샘플 원본 복원, Launch Screen·방향 설정을 다뤘습니다. [문제 대응 문서](docs/troubleshooting.md)는 현재 코드로 확인되는 처리, 이전에 수행한 빌드 검증, 사용자 제공 개발 이력을 구분합니다.

## 현재 상태와 향후 개선 계획

- **확인 완료**: 이전 설정 정리에서 Debug Simulator·Release 기기용 빌드와 서명 없는 Archive 생성 성공
- **준비 중**: TestFlight 계정·서명·업로드 검증. 배포는 아직 완료하지 않았습니다.
- **개선 계획**: 실제 기대값을 검증하는 저장·호환 테스트, 실기기 알림 확인, 사진 압축 경로 통일, 데이터 증가에 따른 파일 저장·데이터베이스 방식 검토

테스트 타깃은 현재 예제 테스트이며 기능 검증이 완비된 상태는 아닙니다. 펫상식은 앱 내장 콘텐츠, 리포트 안내는 기록 조건에 따른 규칙 기반 문구입니다.
