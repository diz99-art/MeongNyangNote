import SwiftUI
import UIKit
import Foundation
import UniformTypeIdentifiers

struct AppBackupData: Codable {
    var createdAt: Date
    var appName: String
    var version: String
    var todayMemo: String?
    var todayMemoPinned: Bool?
    var lastCareResetDate: Date?
    var careItemsData: Data?
    var careRecordsData: Data?
    var weightRecordsData: Data?
    var supplementItemsData: Data?
    var lastSupplementResetDate: Date?
    var dogProfileImageData: Data?
    var selectedTheme: String?
    var recordTypes: [String]?
    var petProfilesData: Data?
    var selectedPetProfileID: String?
}

struct DataManagementView: View {
    @EnvironmentObject private var themeManager: ThemeManager
    @EnvironmentObject private var petStore: PetProfileStore
    @State private var backupURL: URL?
    @State private var showingImporter = false
    @State private var pendingBackup: AppBackupData?
    @State private var showingRestoreConfirmation = false
    @State private var showingResetConfirmation = false
    @State private var alertMessage = ""
    @State private var showingAlert = false

    private let defaults = UserDefaults.standard

    private var backupKeys: [String] {
        ["careItems", "todayMemo", "todayMemoPinned", "lastCareResetDate", "careRecords", "weightRecords", "supplementItems", "lastSupplementResetDate", "dogProfileImageData", "selectedTheme", "recordTypes", "petProfiles", "selectedPetProfileID"]
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("데이터 관리").font(.title2.bold()).foregroundStyle(themeManager.theme.palette.text)
                Text("백업, 복원, 초기화를 관리해요").font(.subheadline).foregroundStyle(.secondary)

                VStack(alignment: .leading, spacing: 10) {
                    Image(systemName: "externaldrive.fill").font(.title2).foregroundStyle(themeManager.theme.palette.accent)
                    Text("기기를 바꾸기 전에는 백업 파일을 만들어두세요.").font(.body).foregroundStyle(themeManager.theme.palette.text).fixedSize(horizontal: false, vertical: true)
                }.careCard()

                VStack(spacing: 10) {
                    Button { createBackupFile() } label: {
                        Label("백업 파일 만들기", systemImage: "square.and.arrow.up").frame(maxWidth: .infinity)
                    }.buttonStyle(.borderedProminent).tint(themeManager.theme.palette.accent)
                    if let backupURL {
                        ShareLink(item: backupURL) {
                            Label("백업 파일 공유하기", systemImage: "arrow.up.doc").frame(maxWidth: .infinity)
                        }.buttonStyle(.bordered)
                    }
                }.careCard()

                VStack(spacing: 10) {
                    Button { showingImporter = true } label: {
                        Label("백업 파일 복원하기", systemImage: "square.and.arrow.down").frame(maxWidth: .infinity)
                    }.buttonStyle(.bordered).tint(themeManager.theme.palette.accent)
                    Button(role: .destructive) { showingResetConfirmation = true } label: {
                        Label("전체 데이터 초기화", systemImage: "trash").frame(maxWidth: .infinity)
                    }.buttonStyle(.bordered)
                }.careCard()

                sampleDataCard
            }.padding(16)
        }
        .background(CareBackground())
        .navigationTitle("데이터 관리")
        .navigationBarTitleDisplayMode(.inline)
        .fileImporter(isPresented: $showingImporter, allowedContentTypes: [.json], allowsMultipleSelection: false, onCompletion: importBackup)
        .alert("데이터 관리", isPresented: $showingAlert) {
            Button("확인", role: .cancel) { }
        } message: { Text(alertMessage) }
        .alert("백업 파일로 복원할까요?", isPresented: $showingRestoreConfirmation) {
            Button("취소", role: .cancel) { pendingBackup = nil }
            Button("복원", role: .destructive) {
                if let pendingBackup { restore(backup: pendingBackup) }
                pendingBackup = nil
            }
        } message: { Text("복원하면 현재 앱 데이터가 덮어써질 수 있어요.") }
        .alert("정말 모든 데이터를 초기화할까요?", isPresented: $showingResetConfirmation) {
            Button("취소", role: .cancel) { }
            Button("초기화", role: .destructive) { resetAllData() }
        } message: { Text("이 작업은 되돌릴 수 없어요. 먼저 백업을 권장해요.") }
    }

    private func makeBackupData() -> AppBackupData {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
        return AppBackupData(createdAt: Date(), appName: "멍냥노트", version: version,
                             todayMemo: defaults.string(forKey: "todayMemo"),
                             todayMemoPinned: defaults.object(forKey: "todayMemoPinned") as? Bool,
                             lastCareResetDate: defaults.object(forKey: "lastCareResetDate") as? Date,
                             careItemsData: defaults.data(forKey: "careItems"), careRecordsData: defaults.data(forKey: "careRecords"),
                             weightRecordsData: defaults.data(forKey: "weightRecords"), supplementItemsData: defaults.data(forKey: "supplementItems"),
                             lastSupplementResetDate: defaults.object(forKey: "lastSupplementResetDate") as? Date,
                             dogProfileImageData: defaults.data(forKey: "dogProfileImageData"), selectedTheme: defaults.string(forKey: "selectedTheme"),
                             recordTypes: defaults.array(forKey: "recordTypes") as? [String], petProfilesData: defaults.data(forKey: "petProfiles"),
                             selectedPetProfileID: defaults.string(forKey: "selectedPetProfileID"))
    }

    private func createBackupFile() {
        do {
            let data = try JSONEncoder().encode(makeBackupData())
            let formatter = DateFormatter(); formatter.dateFormat = "yyyy-MM-dd"
            let url = FileManager.default.temporaryDirectory.appendingPathComponent("MeongNyangNote_Backup_\(formatter.string(from: Date())).json")
            try data.write(to: url, options: .atomic)
            backupURL = url
        } catch { showAlert("백업 파일을 만들지 못했어요") }
    }

    private func importBackup(_ result: Result<[URL], Error>) {
        guard case .success(let urls) = result, let url = urls.first else { return }
        let accessed = url.startAccessingSecurityScopedResource()
        defer { if accessed { url.stopAccessingSecurityScopedResource() } }
        do {
            pendingBackup = try JSONDecoder().decode(AppBackupData.self, from: Data(contentsOf: url))
            showingRestoreConfirmation = true
        } catch { showAlert("백업 파일을 읽지 못했어요") }
    }

    private func restore(backup: AppBackupData) {
        // 복원 후 샘플 삭제가 이전 데이터로 되돌리지 않도록 스냅샷을 해제합니다.
        defaults.removeObject(forKey: "screenshotSampleOriginalData")
        // 부분 백업에서 빠진 키는 현재 값을 보존해 복원 범위를 안전하게 제한합니다.
        setIfPresent(backup.todayMemo, forKey: "todayMemo"); setIfPresent(backup.todayMemoPinned, forKey: "todayMemoPinned")
        setIfPresent(backup.lastCareResetDate, forKey: "lastCareResetDate"); setIfPresent(backup.careItemsData, forKey: "careItems")
        setIfPresent(backup.careRecordsData, forKey: "careRecords"); setIfPresent(backup.weightRecordsData, forKey: "weightRecords")
        setIfPresent(backup.supplementItemsData, forKey: "supplementItems"); setIfPresent(backup.lastSupplementResetDate, forKey: "lastSupplementResetDate")
        setIfPresent(backup.dogProfileImageData, forKey: "dogProfileImageData"); setIfPresent(backup.selectedTheme, forKey: "selectedTheme")
        setIfPresent(backup.recordTypes, forKey: "recordTypes"); setIfPresent(backup.petProfilesData, forKey: "petProfiles")
        setIfPresent(backup.selectedPetProfileID, forKey: "selectedPetProfileID")
        defaults.synchronize(); showAlert("복원이 완료됐어요. 앱을 다시 실행하면 더 정확하게 반영돼요.")
    }

    private func resetAllData() {
        backupKeys.forEach { defaults.removeObject(forKey: $0) }
        defaults.removeObject(forKey: "screenshotSampleOriginalData")
        defaults.synchronize(); showAlert("데이터가 초기화됐어요. 앱을 다시 실행해 주세요.")
    }

    private func setIfPresent<T>(_ value: T?, forKey key: String) {
        if let value { defaults.set(value, forKey: key) }
    }

    private func showAlert(_ message: String) { alertMessage = message; showingAlert = true }

    private var sampleDataCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("스크린샷용 샘플 데이터", systemImage: "sparkles.rectangle.stack")
                .font(.headline)
            Text("몽이와 나비의 프로필과 최근 5일 기록을 채워요. 삭제하면 채우기 전 데이터로 돌아가요.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            HStack(spacing: 10) {
                Button("샘플 데이터 채우기") {
                    do {
                        try SampleDataSeeder.seed()
                        petStore.loadPets()
                        NotificationCenter.default.post(name: .sampleDataDidChange, object: nil)
                        showAlert("스크린샷용 샘플 데이터를 채웠어요.")
                    } catch {
                        showAlert("샘플 데이터를 저장하지 못했어요.")
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(themeManager.theme.palette.accent)
                Button("샘플 데이터 삭제", role: .destructive) {
                    SampleDataSeeder.clear()
                    petStore.loadPets()
                    NotificationCenter.default.post(name: .sampleDataDidChange, object: nil)
                    showAlert("샘플 데이터를 삭제했어요.")
                }
                .buttonStyle(.bordered)
            }
        }
        .careCard()
    }
}

extension Notification.Name {
    static let sampleDataDidChange = Notification.Name("sampleDataDidChange")
}

enum SampleDataSeeder {
    private static let defaults = UserDefaults.standard
    private static let mongID = UUID(uuidString: "A3A7F3B6-5B8A-4B8F-9A7B-111111111111")!
    private static let nabiID = UUID(uuidString: "B4B8F4C7-6C9B-4C90-A8C8-222222222222")!

    private static let snapshotKey = "screenshotSampleOriginalData"
    private static let sampleKeys = ["petProfiles", "selectedPetProfileID", "careItems", "todayMemo",
                                     "todayMemoPinned", "lastCareResetDate", "careRecords", "supplementItems",
                                     "lastSupplementResetDate", "weightRecords", "dogProfileImageData"]

    static func seed() throws {
        // 반복해서 눌러도 최초 원본을 보존합니다. 기존 저장 키와 JSON 형식은 유지합니다.
        if defaults.data(forKey: snapshotKey) == nil {
            let original = sampleKeys.reduce(into: [String: Any]()) { result, key in
                result[key] = defaults.object(forKey: key)
            }
            let snapshot = try PropertyListSerialization.data(fromPropertyList: original, format: .binary, options: 0)
            defaults.set(snapshot, forKey: snapshotKey)
        }
        defaults.removeObject(forKey: "dogProfileImageData")
        let mongImage = sampleImageData(named: "sample_dog_mongi")
        let nabiImage = sampleImageData(named: "sample_cat_nabi")
        let mong = PetProfile(id: mongID, name: "몽이", species: "강아지", breed: "말티푸", ageText: "2살",
                              traits: ["눈물 관리 필요", "슬개골 관리 중", "유산균 급여 중"], imageData: mongImage)
        let nabi = PetProfile(id: nabiID, name: "나비", species: "고양이", breed: "코리안숏헤어", ageText: "3살",
                              traits: ["헤어볼 관리 필요", "습식 사료 선호", "낯가림 있음"], imageData: nabiImage)
        try save([mong, nabi], forKey: "petProfiles")
        defaults.set(mongID.uuidString, forKey: "selectedPetProfileID")

        let careItems = [
            CareItem(title: "아침 식사", isCompleted: true, petID: mongID),
            CareItem(title: "저녁 식사", petID: mongID),
            CareItem(title: "산책", isCompleted: true, petID: mongID),
            CareItem(title: "양치", petID: mongID),
            CareItem(title: "오메가3", isCompleted: true, petID: mongID),
            CareItem(title: "눈물 상태 확인", petID: mongID)
        ]
        try save(careItems, forKey: "careItems")
        defaults.set("오늘도 산책 잘했고 밥도 잘 먹었어요 🐶", forKey: "todayMemo")
        defaults.set(true, forKey: "todayMemoPinned")
        defaults.set(Date(), forKey: "lastCareResetDate")

        // 몸무게 화면과 기록 탭이 같은 데모 흐름을 보여주도록 기존 연동 형식의 기록도 함께 만듭니다.
        let weights = makeWeights()
        let weightRecords = weights.map { weight in
            let amount = weight.weight.formatted(.number.locale(Locale(identifier: "en_US_POSIX")).precision(.fractionLength(0...3)))
            let memo = "몸무게: \(amount)kg" + (weight.memo.isEmpty ? "" : "\n\(weight.memo)")
            return CareRecord(type: "몸무게", date: weight.date, title: "몸무게 기록", memo: memo,
                              mealAmount: nil, walkMinutes: nil, symptoms: [], imageData: nil, petID: weight.petID)
        }
        try save(makeRecords() + weightRecords + makePhotoRecords(mongImage: mongImage, nabiImage: nabiImage), forKey: "careRecords")
        let supplements = [
            SupplementItem(title: "오메가3", isCompleted: true, category: "영양제", dosage: "1캡슐", timeText: "오전 8:30", memo: "식후 급여", isReminderEnabled: true, reminderHour: 8, reminderMinute: 30, petID: mongID),
            SupplementItem(title: "유산균", category: "영양제", dosage: "1포", timeText: "오후 8:00", memo: "사료에 섞어서 급여", isReminderEnabled: true, reminderHour: 20, petID: mongID),
            SupplementItem(title: "관절 영양제", isCompleted: true, category: "영양제", dosage: "1정", timeText: "오후 7:00", memo: "산책 후 급여", petID: mongID),
            SupplementItem(title: "헤어볼 영양제", category: "영양제", dosage: "1회", timeText: "오후 9:00", memo: "간식처럼 급여", isReminderEnabled: true, reminderHour: 21, petID: nabiID)
        ]
        try save(supplements, forKey: "supplementItems")
        defaults.set(Date(), forKey: "lastSupplementResetDate")
        try save(weights, forKey: "weightRecords")
    }

    static func clear() {
        guard let snapshot = defaults.data(forKey: snapshotKey),
              let original = try? PropertyListSerialization.propertyList(from: snapshot, options: [], format: nil) as? [String: Any] else { return }
        for key in sampleKeys {
            if let value = original[key] { defaults.set(value, forKey: key) }
            else { defaults.removeObject(forKey: key) }
        }
        defaults.removeObject(forKey: snapshotKey)
    }

    // UserDefaults에 원본 대형 PNG 대신 최대 512px JPEG를 저장합니다.
    // 에셋 누락/변환 실패는 nil로 전달하여 기존 placeholder를 사용합니다.
    private static func sampleImageData(named name: String) -> Data? {
        guard let image = UIImage(named: name), image.size.width > 0, image.size.height > 0 else { return nil }
        let scale = min(1, 512 / max(image.size.width, image.size.height))
        let size = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true
        return UIGraphicsImageRenderer(size: size, format: format).image { _ in
            image.draw(in: CGRect(origin: .zero, size: size))
        }.jpegData(compressionQuality: 0.8)
    }

    private static func makePhotoRecords(mongImage: Data?, nabiImage: Data?) -> [CareRecord] {
        // 앨범은 반려동물별로 필터링하므로 각각 두 개의 사진 기록을 제공합니다.
        [
            CareRecord(type: "기타", date: date(0, 10, 0), title: "산책 후 사진", memo: "산책 후 기분 좋은 모습",
                       mealAmount: nil, walkMinutes: nil, symptoms: [], imageData: mongImage, petID: mongID),
            CareRecord(type: "기타", date: date(1, 10, 0), title: "공원에서 한 컷", memo: "포근한 햇살 아래 잠깐 쉬었어요",
                       mealAmount: nil, walkMinutes: nil, symptoms: [], imageData: mongImage, petID: mongID),
            CareRecord(type: "기타", date: date(0, 13, 0), title: "낮잠 사진", memo: "창가에서 낮잠 잔 날",
                       mealAmount: nil, walkMinutes: nil, symptoms: [], imageData: nabiImage, petID: nabiID),
            CareRecord(type: "기타", date: date(1, 13, 0), title: "햇살 아래 나비", memo: "좋아하는 쿠션에서 편안하게 쉬어요",
                       mealAmount: nil, walkMinutes: nil, symptoms: [], imageData: nabiImage, petID: nabiID)
        ]
    }

    private static func save<T: Encodable>(_ value: T, forKey key: String) throws {
        defaults.set(try JSONEncoder().encode(value), forKey: key)
    }

    // 0은 오늘, 4는 나흘 전입니다. 자정 직후에도 미래 기록을 만들지 않습니다.
    private static func date(_ daysAgo: Int, _ hour: Int, _ minute: Int) -> Date {
        let now = Date()
        let calendar = Calendar.current
        let day = calendar.date(byAdding: .day, value: -daysAgo, to: calendar.startOfDay(for: now)) ?? now
        let timestamp = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: day) ?? day
        return min(timestamp, now)
    }

    private static func makeRecords() -> [CareRecord] {
        [
            CareRecord(type: "식사", date: date(4, 8, 10), title: "아침 식사", memo: "사료를 거의 다 먹었어요", mealAmount: "잘 먹음", walkMinutes: nil, symptoms: [], petID: mongID),
            CareRecord(type: "산책", date: date(4, 19, 20), title: "저녁 산책", memo: "공원에서 28분 산책", mealAmount: nil, walkMinutes: 28, symptoms: [], petID: mongID),
            CareRecord(type: "증상", date: date(4, 21, 0), title: "눈물 상태", memo: "평소보다 조금 많았어요", mealAmount: nil, walkMinutes: nil, symptoms: ["눈물 증가"], petID: mongID),
            CareRecord(type: "식사", date: date(3, 8, 0), title: "아침 식사", memo: "사료와 간식 조금 먹음", mealAmount: "보통", walkMinutes: nil, symptoms: [], petID: mongID),
            CareRecord(type: "영양제", date: date(3, 8, 15), title: "오메가3 급여", memo: "식사 후 급여 완료", mealAmount: nil, walkMinutes: nil, symptoms: [], petID: mongID),
            CareRecord(type: "산책", date: date(3, 18, 50), title: "저녁 산책", memo: "짧게 15분 산책", mealAmount: nil, walkMinutes: 15, symptoms: [], petID: mongID),
            CareRecord(type: "병원", date: date(3, 14, 30), title: "정기 검진", memo: "슬개골 상태 체크, 특이사항 없음", mealAmount: nil, walkMinutes: nil, symptoms: [], petID: mongID),
            CareRecord(type: "기타", date: date(2, 10, 0), title: "목욕", memo: "샴푸 후 드라이까지 완료", mealAmount: nil, walkMinutes: nil, symptoms: [], petID: mongID),
            CareRecord(type: "식사", date: date(2, 8, 5), title: "아침 식사", memo: "사료를 깔끔하게 다 먹음", mealAmount: "잘 먹음", walkMinutes: nil, symptoms: [], petID: mongID),
            CareRecord(type: "산책", date: date(2, 19, 10), title: "저녁 산책", memo: "비가 와서 실내 놀이로 대체", mealAmount: nil, walkMinutes: 10, symptoms: [], petID: mongID),
            CareRecord(type: "증상", date: date(2, 21, 10), title: "컨디션 메모", memo: "기분 좋고 활발했어요", mealAmount: nil, walkMinutes: nil, symptoms: [], petID: mongID),
            CareRecord(type: "기타", date: date(1, 9, 30), title: "양치 완료", memo: "치석 관리용 껌도 함께 급여", mealAmount: nil, walkMinutes: nil, symptoms: [], petID: mongID),
            CareRecord(type: "식사", date: date(3, 7, 40), title: "아침 식사", memo: "습식 사료 절반 정도 먹음", mealAmount: "보통", walkMinutes: nil, symptoms: [], petID: nabiID),
            CareRecord(type: "기타", date: date(3, 20, 0), title: "놀이 시간", memo: "낚싯대 장난감으로 12분 놀이", mealAmount: nil, walkMinutes: nil, symptoms: [], petID: nabiID),
            CareRecord(type: "증상", date: date(2, 11, 0), title: "헤어볼 관리", memo: "소량의 헤어볼, 이후 상태 양호", mealAmount: nil, walkMinutes: nil, symptoms: ["헤어볼"], petID: nabiID),
            CareRecord(type: "식사", date: date(0, 8, 10), title: "아침 식사", memo: "사료를 거의 다 먹었어요", mealAmount: "잘 먹음", walkMinutes: nil, symptoms: [], petID: mongID),
            CareRecord(type: "산책", date: date(0, 9, 0), title: "아침 산책", memo: "공원에서 28분 산책", mealAmount: nil, walkMinutes: 28, symptoms: [], petID: mongID),
            CareRecord(type: "영양제", date: date(0, 8, 30), title: "오메가3 급여", memo: "식사 후 급여 완료", mealAmount: nil, walkMinutes: nil, symptoms: [], petID: mongID),
            CareRecord(type: "식사", date: date(0, 18, 0), title: "저녁 간식", memo: "간식 조금 먹음", mealAmount: "조금", walkMinutes: nil, symptoms: [], petID: nabiID),
            CareRecord(type: "영양제", date: date(0, 21, 0), title: "헤어볼 영양제 급여", memo: "간식처럼 급여", mealAmount: nil, walkMinutes: nil, symptoms: [], petID: nabiID)
        ]
    }

    private static func makeWeights() -> [WeightRecord] {
        [
            WeightRecord(date: date(4, 9, 0), weight: 4.1, memo: "컨디션 양호", petID: mongID),
            WeightRecord(date: date(3, 9, 0), weight: 4.2, memo: "식욕 좋음", petID: mongID),
            WeightRecord(date: date(1, 9, 0), weight: 4.15, memo: "유지 중", petID: mongID),
            WeightRecord(date: date(0, 9, 0), weight: 4.25, memo: "최근 활발함", petID: mongID),
            WeightRecord(date: date(4, 9, 0), weight: 5.0, memo: "습식 위주", petID: nabiID),
            WeightRecord(date: date(2, 9, 0), weight: 5.1, memo: "상태 안정적", petID: nabiID),
            WeightRecord(date: date(0, 9, 0), weight: 5.05, memo: "큰 변화 없음", petID: nabiID)
        ]
    }
}
