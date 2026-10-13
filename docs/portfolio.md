# 멍냥노트 — 설계와 구현 포트폴리오

반려동물별 생활 기록과 오늘의 케어를 연결하는 SwiftUI iOS 앱입니다. **TestFlight 준비 중**이며 업로드는 잠시 중단한 상태입니다. [README](../README.md)는 기능과 화면을, 이 문서는 구현 선택과 한계를 설명합니다.

## 사용자 흐름과 화면

첫 사용 안내 → 프로필 선택 → 케어 체크·기록 작성 → 사진과 월간 리포트 확인으로 이어집니다. 홈·기록·영양제·펫상식은 4개 탭이고 관리 화면에서 프로필·백업·테마 등의 기능에 접근합니다.

| 홈 | 기록 | 월간 리포트 |
| --- | --- | --- |
| ![멍냥노트 홈](../screenshots/01_home_promo.png) | ![멍냥노트 기록](../screenshots/02_records_promo.png) | ![멍냥노트 월간 리포트](../screenshots/03_report_promo.png) |
| 오늘의 케어와 한 줄 메모 | 달력으로 확인하는 생활 기록 | 기록 건수·산책 시간·체중 변화 |

| 영양제 | 펫상식 |
| --- | --- |
| ![멍냥노트 영양제](../screenshots/04_supplement_promo.png) | ![멍냥노트 펫상식](../screenshots/05_tips_promo.png) |
| 급여 체크와 시간 알림 | 강아지·고양이 생활 상식 |

## 화면과 구현 연결

| 구현 파일 | 담당 기능 |
| --- | --- |
| `DangDangNoteApp.swift`, `ContentView.swift` | 앱 진입점, 공용 상태, 온보딩과 4개 탭 |
| `HomeView.swift` | 오늘의 케어, 공용 메모, 산책 타이머, 케어 알림 |
| `PetProfileStore.swift`, `PetManagementView.swift`, `DogProfileView.swift` | 여러 마리 프로필과 선택 상태, 프로필 편집 |
| `AddRecordView.swift`, `HistoryView.swift` | 유형별 기록 입력, 저장, 날짜별 조회와 삭제 |
| `SupplementCheckView.swift` | 영양제 편집, 완료 체크, 반복 알림 |
| `WeightRecordView.swift` | 체중 기록과 케어 기록 연동 |
| `PhotoAlbumView.swift` | 기록 첨부 사진 모아보기 |
| `MonthlyReportView.swift` | 선택한 반려동물과 월 기준의 집계 |
| `PetTipsView.swift` | 강아지·고양이 상식 콘텐츠 |
| `ManagementView.swift`, `DataManagementView.swift` | 관리 메뉴, 테마, 백업·복원·초기화 |

파일은 저장소의 `DangDangNote/`에 있습니다. 화면 내부에 모델과 저장 헬퍼가 함께 정의된 부분도 있습니다.

## 1. 서버 없이 기록을 시작하기

**문제:** 기본 케어 기록을 사용하기 위해 로그인과 서버 구성이 선행되면 초기 사용과 운영 부담이 커집니다.

**해결:** 현재 범위에 맞춰 Foundation·Codable·UserDefaults로 기기 내 저장을 구성했습니다. 네트워크 백엔드 없이 프로필·기록을 입력하고 다시 불러올 수 있습니다.

**결과와 판단:** 단순한 저장 흐름으로 기능을 구성하고 JSON 백업으로 기기 이동 경로를 제공합니다. 다만 이 선택의 설계상 장점을 설명하는 것이며, 당시 의사결정 기록을 재현한 것은 아닙니다. UserDefaults에 배열 전체와 이미지 Data를 저장하므로 대용량 데이터, 부분 갱신, 검색 성능에는 한계가 있습니다. 이후 파일 기반 사진 저장과 데이터베이스 도입을 검토할 수 있습니다.

| 키 | 저장 내용 |
| --- | --- |
| `petProfiles`, `selectedPetProfileID` | 프로필 목록과 선택 상태 |
| `careItems`, `careRecords` | 체크 항목과 생활 기록 |
| `supplementItems`, `weightRecords` | 영양제와 체중 |
| `todayMemo`, `todayMemoPinned`, `selectedTheme` | 공용 메모·고정 여부·테마 |

## 2. 여러 마리 데이터와 기존 기록의 공존

**문제:** 프로필이 여러 개이면 기록의 소유자를 구분해야 합니다. 기존 저장 데이터에는 `petID`가 없습니다.

**해결:** PetProfileStore는 ObservableObject·Published로 목록과 선택 상태를 관리하고, 화면이 EnvironmentObject로 참조합니다. 새 기록에 `petID`를 저장하고 조회 시 선택한 프로필로 필터링합니다. 이전 ID 없는 데이터는 `isLegacyPetSelected` 조건을 통해 첫 번째 기본 프로필에서 조회합니다.

**결과와 판단:** 기존 데이터를 모두 재작성하지 않고 조회 단계에서 호환성을 유지합니다. 메모·테마는 앱 공용이며 모든 데이터가 프로필별로 독립된 것은 아닙니다. 첫 번째 프로필 기준 호환 방식은 목록 변화 시의 의미도 검증할 필요가 있습니다. 영양제 급여 기록 중복 검사는 현재 날짜·유형·제목 기준이므로 같은 이름의 여러 반려동물 항목은 추가 테스트 대상입니다.

## 3. 상태와 첫 사용 안내

**문제:** 앱 진입 화면과 안내가 여러 경로에서 표시되면 중복되거나 완료 상태를 잃을 수 있습니다.

**해결:** DangDangNoteApp은 ContentView로 진입하고, `hasSeenOnboarding` AppStorage 값으로 OnboardingView와 mainTabs를 분기합니다. 각 탭에는 NavigationStack이 있으며 ThemeManager로 테마를 공유합니다.

**결과:** 안내 완료 후 메인 탭으로 전환하고 완료 상태를 저장합니다. SplashView·StartView 파일은 존재하지만 현재 진입 흐름에서는 호출하지 않습니다. 과거 중복 현상의 오류 로그는 없으므로 현재 구조를 근거로 설명합니다.

## 4. 사진·알림과 실패 처리

**문제:** 사진 선택은 비동기 작업이며 데이터가 없거나 변환에 실패할 수 있습니다. 로컬 알림은 사용자 권한에 의존합니다.

**해결:** PhotosPicker의 로딩 결과를 검사하고 화면별 오류 안내·대체 표시를 둡니다. DogProfileView는 취소된 작업의 결과를 적용하지 않고, 기록 사진은 축소 JPEG로 저장합니다. 영양제 저장 시 알림 권한 거부를 확인해 알림 상태를 해제하고 안내합니다.

**결과와 한계:** 사진 없이도 프로필과 기록을 표시할 수 있고, 권한 거부를 사용자에게 알립니다. PetManagementView는 선택한 Data를 그대로 저장하므로 모든 사진에 같은 압축·변환 검증이 적용되지는 않습니다. 실기기 반복 알림과 권한 변경 검증은 남아 있습니다.

## 5. 기록을 리포트와 백업으로 연결하기

**문제:** 날짜별 목록만으로는 한 달의 관리 흐름을 파악하거나 다른 기기로 옮기기 어렵습니다.

**해결:** MonthlyReportView가 월과 petID로 필터링해 유형별 건수, 산책 시간 합계, 사진 수, 첫·마지막 체중의 차이를 집계합니다. DataManagementView는 AppBackupData를 JSON으로 만들어 ShareLink로 공유하고 fileImporter로 복원합니다. 일부 값이 없는 백업은 현재 값을 보존하며 복원 후 재실행을 안내합니다.

**결과:** 저장된 기록에서 요약을 만들고 수동 백업 경로를 제공합니다. 리포트 문구는 조건 기반이며 건강 진단이나 AI 분석 기능은 아닙니다. 앱 상태 전체가 실시간 재동기화되거나 자동 클라우드 백업되는 방식도 아닙니다.

## 6. 샘플 화면과 배포 설정 준비

**문제:** 실제 개인정보 없이 일정한 홍보 화면을 구성하고, 배포 준비 설정을 검증해야 합니다.

**해결:** SampleDataSeeder로 예시 프로필·사진·기록·체중·영양제를 만들고 최초 적용 전 저장값을 스냅샷으로 보존합니다. 샘플 해제 시 원본을 복원합니다. 배포 설정 정리에서는 명시적 Info.plist를 유지하고 잘못된 `UILaunchScreen=false`와 빈 상태바 값을 제거했습니다. 기존 LaunchScreen.storyboard와 iPhone 전용 Portrait 설정을 사용합니다.

**결과:** 홍보 PNG 5장을 포트폴리오에 연결했습니다. 이전 작업에서 Debug Simulator·Release 기기용 빌드와 서명 없는 Archive가 성공했고 생성 plist와 컴파일된 시작 화면을 확인했습니다. Bundle ID·Team·Automatic signing은 유지했습니다. 이 검증은 TestFlight용 서명·업로드 성공을 의미하지 않습니다.

## 검증과 다음 개선

현재 테스트 타깃은 예제 테스트입니다. 다음 개선 대상으로 저장 오류·레거시 데이터·동일 이름의 다중 프로필 테스트, 사진 저장 일관성, 실기기 알림, 대용량 성능을 두고 있습니다. 배포 계정 상태와 업로드 검증은 별도로 진행해야 합니다.

[문제 대응 상세](troubleshooting.md) · [스크린샷 안내](../screenshots/README.md) · [샘플 이미지 출처](sample-image-provenance.md)
