# 구현에서 확인되는 문제 대응

아래 내용은 현재 코드와 주석으로 확인되는 방어 처리입니다. 개발 당시의 오류 로그나 재현 기록이 없어, 특정 장애를 재현·해결한 이력으로 단정하지 않습니다.

## 여러 마리 도입 전 데이터의 표시

**문제 상황:** 이전 데이터에는 반려동물 ID가 없어 여러 프로필에 같은 기록이 표시될 수 있습니다.

**현재 처리:** `PetProfileStore.isLegacyPetSelected`로 첫 번째 기본 프로필을 판별합니다. 기록·사진 앨범·월간 리포트의 조회 조건은 선택한 `petID` 또는 기본 프로필의 ID 없는 데이터를 포함합니다.

**근거:** `PetProfileStore.swift`, `HistoryView.swift`, `PhotoAlbumView.swift`, `MonthlyReportView.swift`.

## 저장 실패 시 입력값과 기존 기록 보존

**문제 상황:** 기존 JSON을 읽지 못한 상태에서 새 배열로 덮어쓰면 기존 기록이 사라질 수 있습니다.

**현재 처리:** `CareRecordStorage.append`는 기존 데이터를 먼저 디코딩하고, 새 배열을 인코딩한 뒤 저장합니다. 실패하면 오류를 전달하며 `AddRecordView.saveRecord`는 성공한 경우에만 입력값을 초기화합니다. 삭제도 최신 목록에서 지정 ID만 제거합니다.

**근거:** `AddRecordView.swift`의 `CareRecordStorage`, `saveRecord`.

## 체중과 케어 기록의 연동

**문제 상황:** 조회 때마다 연동 기록을 만들면 중복이 생기고, 인코딩 실패 중 일부만 저장하면 두 목록이 어긋날 수 있습니다.

**현재 처리:** `appendWithCareRecord`는 새 체중 추가 시에 호출합니다. 기존 체중 디코딩과 새 체중 인코딩을 먼저 수행한 뒤 케어 기록을 추가하고 체중 데이터를 저장합니다. 코드 주석도 조회·삭제 시 연동하지 않도록 명시합니다. 이는 데이터베이스 트랜잭션 보장을 의미하지 않습니다.

**근거:** `WeightRecordView.swift`의 `WeightRecordStorage`.

## 이미지 저장 크기 줄이기

**문제 상황:** UserDefaults에 큰 원본 이미지를 넣으면 저장 데이터 크기가 증가합니다.

**현재 처리:** 기록 사진은 긴 변 최대 900과 JPEG 품질 0.7로 변환합니다. `DogProfileView`의 프로필 사진 및 샘플 이미지에는 최대 512 크기의 JPEG 변환 처리가 있습니다. 모든 사진 경로에 동일한 제한이 적용된다고 가정하지 않습니다.

**근거:** `AddRecordView.swift`, `DogProfileView.swift`, `DataManagementView.swift`.

## 날짜가 바뀌어도 남는 완료 표시

**문제 상황:** 전날 체크가 남으면 오늘의 상태와 혼동할 수 있습니다.

**현재 처리:** 마지막 초기화 날짜와 오늘을 비교해 완료 상태를 해제합니다. 홈 케어는 전체 프로필의 항목을 초기화한 뒤 선택한 프로필의 항목을 다시 불러옵니다. 앱이 날짜 변경을 확인하는 시점에 처리됩니다.

**근거:** `HomeView.resetCareItemsIfNeeded`, `SupplementCheckView.resetSupplementItemsIfNeeded`.

## 알림 권한 거부와 예약 취소

**문제 상황:** 사용자가 권한을 거부하면 알림 설정을 켰어도 실제 알림이 오지 않을 수 있습니다.

**현재 처리:** 영양제 저장 시 권한 요청 결과를 확인하고, 거부 시 알림 상태를 해제하며 안내를 표시합니다. 영양제 삭제와 알림 해제 시 예약 알림을 취소합니다.

**근거:** `SupplementCheckView.swift`의 `saveItem`, `deleteItem`, `SupplementNotificationManager`.

**남은 확인:** 실기기에서 권한 변경, 잠금 상태, 반복 알림 수신은 별도 확인이 필요합니다.

## 부분 백업 복원과 샘플 데이터

**문제 상황:** 백업에서 빠진 값이 현재 데이터를 지우거나, 샘플 삭제가 복원 전 상태로 되돌릴 수 있습니다.

**현재 처리:** 복원 전 `screenshotSampleOriginalData` 스냅샷을 제거하고, `setIfPresent`로 백업에 존재하는 값만 반영합니다. 복원 후 재실행을 안내합니다.

**근거:** `DataManagementView.swift`의 `restore`, `setIfPresent`.

## 검증 범위

이번 문서 정리는 소스와 프로젝트 설정을 대조했습니다. 새로운 기능 테스트나 빌드를 수행한 결과로 소개하지 않습니다. `DangDangNoteTests.swift`는 예제 테스트이며 실제 동작의 검증 결과를 포함하지 않습니다.
