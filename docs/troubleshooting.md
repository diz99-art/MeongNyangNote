# 멍냥노트 — 문제 대응과 검증

현재 소스에서 확인한 처리, 이전 설정 작업에서 수행한 검증, 사용자 제공 개발 이력을 구분해 정리했습니다. 오류 로그가 없는 항목은 과거 장애를 재현·해결했다고 단정하지 않습니다.

## 첫 실행 화면 중복과 진입 구조

- **문제:** 시작 화면과 온보딩이 여러 진입 경로에 있으면 같은 안내가 반복될 수 있습니다.
- **처리:** DangDangNoteApp → ContentView를 단일 앱 진입 흐름으로 사용하고, `hasSeenOnboarding`으로 첫 안내와 탭을 분기합니다. OnboardingView의 완료 콜백이 값을 저장합니다.
- **결과:** 현재 흐름에서 SplashView·StartView를 추가 호출하지 않습니다. 시스템 LaunchScreen.storyboard와 앱 내부 온보딩은 역할이 구분됩니다.
- **근거·한계:** [ContentView](../DangDangNote/ContentView.swift), [OnboardingView](../DangDangNote/OnboardingView.swift). 과거 중복 화면의 재현 로그는 확인하지 못했습니다.

## 샘플 데이터와 App Store 스크린샷 준비

- **문제:** 실제 기록을 노출하지 않으면서 목록·리포트·체크 상태가 채워진 화면이 필요합니다.
- **처리:** SampleDataSeeder가 몽이·나비 프로필과 케어·영양제·사진·체중 기록을 구성합니다. 최초 샘플 적용 전에 관련 키의 저장값을 스냅샷으로 보존하며, 반복 적용으로 최초 원본을 덮어쓰지 않습니다. `clear`는 그 원본을 복원합니다.
- **결과:** [홍보 이미지 5장](../screenshots/README.md)을 포트폴리오에 사용합니다. 샘플 해제는 샘플 적용 전 상태로 돌아가므로 적용 후 입력한 내용이 보존된다고 설명하지 않습니다.
- **근거:** [DataManagementView](../DangDangNote/DataManagementView.swift), [이미지 출처](sample-image-provenance.md).

## petID 없는 기존 데이터 호환

- **문제:** 다중 프로필 도입 전 기록에는 반려동물 ID가 없습니다.
- **처리:** `isLegacyPetSelected`로 첫 번째 기본 프로필을 판단하고 선택한 petID와 함께 조회 조건에 사용합니다. CareRecord 등의 디코딩은 선택 필드의 누락을 허용합니다.
- **결과:** 이전 기록을 조회할 수 있으며 모든 프로필에 동일 기록을 노출하는 것을 제한합니다. 첫 번째 프로필 변경·삭제 시 의미는 추가 검증 대상입니다.
- **근거:** [PetProfileStore](../DangDangNote/PetProfileStore.swift), [HistoryView](../DangDangNote/HistoryView.swift), [MonthlyReportView](../DangDangNote/MonthlyReportView.swift).

## 사진 Data nil·변환 실패 처리

- **문제:** 선택 사진의 로딩·이미지 변환이 실패하거나 샘플 에셋이 없을 수 있습니다.
- **처리:** DogProfileView는 Data·UIImage·JPEG 변환 결과를 검사하고 실패를 안내하며 취소 작업 결과를 적용하지 않습니다. AddRecordView는 로딩·UIImage 실패 시 안내하고 압축 결과를 optional Data로 저장합니다. SampleDataSeeder는 에셋 누락·변환 실패를 nil로 전달합니다.
- **결과:** 이미지가 없어도 대체 프로필 표시를 사용할 수 있고 앨범은 유효한 이미지 데이터만 표시합니다.
- **한계:** PetManagementView는 로딩 결과 Data를 그대로 저장합니다. 모든 경로에 압축이나 동일한 변환 실패 처리가 있다고 설명하지 않습니다.
- **근거:** [DogProfileView](../DangDangNote/DogProfileView.swift), [AddRecordView](../DangDangNote/AddRecordView.swift), [PhotoAlbumView](../DangDangNote/PhotoAlbumView.swift), [PetManagementView](../DangDangNote/PetManagementView.swift).

## 알림 권한 거부와 예약 취소

- **문제:** 권한 거부 상태에서는 알림을 켜도 실제 알림이 오지 않을 수 있습니다.
- **처리:** 영양제 저장 시 권한 요청 결과를 확인해 거부 시 알림 상태를 해제하고 안내합니다. 항목 삭제·알림 해제 시 예약 요청을 취소합니다.
- **결과·한계:** 권한 결과에 맞춘 상태 처리가 있습니다. 실기기 권한 변경·잠금 상태·반복 알림 수신은 별도 검증이 필요합니다.
- **근거:** [SupplementCheckView](../DangDangNote/SupplementCheckView.swift)의 saveItem·SupplementNotificationManager.

## 저장 실패와 부분 백업 복원

- **문제:** 디코딩 실패 상태에서 새 데이터를 덮어쓰거나 불완전한 백업으로 현재 값을 지울 수 있습니다.
- **처리:** CareRecordStorage는 기존 목록 디코딩·추가·인코딩 후 저장하며 실패를 전달합니다. AddRecordView는 성공 시에만 입력을 초기화합니다. 체중은 추가 시에만 케어 기록과 연결하며 먼저 체중 데이터를 인코딩합니다. 백업 복원은 존재하는 필드만 반영하고 샘플 원본 스냅샷을 해제합니다.
- **결과·한계:** 실패 시 입력 보존과 부분 복원 처리가 있습니다. UserDefaults 기반이므로 데이터베이스 트랜잭션 보장으로 소개하지 않습니다.
- **근거:** [AddRecordView](../DangDangNote/AddRecordView.swift), [WeightRecordView](../DangDangNote/WeightRecordView.swift), [DataManagementView](../DangDangNote/DataManagementView.swift).

## Info.plist·Launch Screen·화면 방향 정리

- **문제:** 명시적 plist가 참조되는 상태에서 `UILaunchScreen`에 Boolean false가 들어 있었고, 빈 상태바 값과 4방향 설정이 함께 있었습니다. Apple의 UILaunchScreen 정의는 Dictionary입니다. [Apple 문서](https://developer.apple.com/documentation/bundleresources/information-property-list/uilaunchscreen)
- **처리:** 명시적 [Info.plist](../DangDangNote/Info.plist)를 유지하고 잘못된 값을 제거했습니다. 기존 [LaunchScreen.storyboard](../DangDangNote/LaunchScreen.storyboard)를 사용하며 빈 상태바 설정을 제거하고 앱 Debug·Release를 iPhone 전용 Portrait로 정리했습니다. Bundle ID·Team·Automatic signing은 유지했습니다.
- **검증 결과:** 이전 작업에서 plist 문법 검사, Debug Simulator 빌드, Release 기기용 빌드, 서명 없는 Archive 생성이 성공했습니다. 생성 plist에서 UILaunchScreen·빈 상태바 값 부재, UILaunchStoryboardName=LaunchScreen, Portrait 배열, UIDeviceFamily=[1] 및 컴파일된 storyboard 리소스를 확인했습니다.
- **범위:** 설정 커밋 `3f3bbf58e9f11083f2eee6b85c9715d172528109` 기준 검증이며, 이번 문서 작업에서 빌드를 재실행하지 않았습니다. 서명 없는 Archive는 TestFlight 업로드 검증과 별개입니다.

## Personal Team과 TestFlight 계정 준비

- **문제:** 사용자 제공 개발 이력에서는 Personal Team 표시로 TestFlight 업로드 준비가 막혔고, 앱 코드보다 개발자 계정 활성화 문제로 분류했습니다.
- **판단:** Apple은 개발자 프로그램 멤버십과 연결되지 않은 계정이 Xcode에서 Personal Team으로 표시된다고 안내합니다. 따라서 이 문제는 앱 기능 코드를 수정하는 대신 멤버십 활성화·팀 연결·배포 권한을 확인해야 하는 계정 문제로 다뤘습니다. [Apple 계정 안내](https://developer.apple.com/help/account/basics/about-your-developer-account)
- **현재 결과:** TestFlight는 준비 중이며 업로드는 잠시 중단했습니다. 계정 활성화 완료나 업로드 성공을 확인한 것은 아닙니다. 프로그램 가입 후 TestFlight 배포 환경을 확인해야 합니다. [Apple 배포 안내](https://developer.apple.com/documentation/xcode/distributing-your-app-for-beta-testing-and-releases)
- **증거 범위:** 과거 계정 문제는 사용자 제공 이력이며, 이번 작업에서 Xcode 계정 화면·멤버십·서명 인증서를 조회하지 않았습니다.

## 남은 검증

예제 테스트를 실제 저장·호환 테스트로 확장하고, 다중 프로필·동일 제목 영양제 기록, 날짜 변경, 사진 변환 경로, 실기기 알림을 확인할 필요가 있습니다. [구현 상세와 개선 계획](portfolio.md)을 참고하세요.
