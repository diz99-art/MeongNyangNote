import SwiftUI
import UserNotifications
import UIKit

struct SupplementItem: Identifiable, Codable, Equatable {
    var id = UUID()
    var title: String
    var isCompleted = false
    var category = "기타"
    var dosage = ""
    var timeText = ""
    var memo = ""
    var isReminderEnabled = false
    var reminderHour = 9
    var reminderMinute = 0
    var petID: UUID? = nil

    enum CodingKeys: String, CodingKey { case id, title, isCompleted, category, dosage, timeText, memo, isReminderEnabled, reminderHour, reminderMinute, petID }
    init(id: UUID = UUID(), title: String, isCompleted: Bool = false, category: String = "기타", dosage: String = "", timeText: String = "", memo: String = "", isReminderEnabled: Bool = false, reminderHour: Int = 9, reminderMinute: Int = 0, petID: UUID? = nil) {
        self.id = id; self.title = title; self.isCompleted = isCompleted; self.category = category; self.dosage = dosage; self.timeText = timeText; self.memo = memo; self.isReminderEnabled = isReminderEnabled; self.reminderHour = reminderHour; self.reminderMinute = reminderMinute; self.petID = petID
    }
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        title = try c.decode(String.self, forKey: .title)
        isCompleted = try c.decodeIfPresent(Bool.self, forKey: .isCompleted) ?? false
        category = try c.decodeIfPresent(String.self, forKey: .category) ?? "기타"
        dosage = try c.decodeIfPresent(String.self, forKey: .dosage) ?? ""
        timeText = try c.decodeIfPresent(String.self, forKey: .timeText) ?? ""
        memo = try c.decodeIfPresent(String.self, forKey: .memo) ?? ""
        isReminderEnabled = try c.decodeIfPresent(Bool.self, forKey: .isReminderEnabled) ?? false
        reminderHour = try c.decodeIfPresent(Int.self, forKey: .reminderHour) ?? 9
        reminderMinute = try c.decodeIfPresent(Int.self, forKey: .reminderMinute) ?? 0
        petID = try c.decodeIfPresent(UUID.self, forKey: .petID)
    }
}

enum SupplementNotificationManager {
    private static func identifier(for item: SupplementItem) -> String { "supplementReminder-\(item.petID?.uuidString ?? "legacy")-\(item.id.uuidString)" }
    static func requestAuthorization() async -> Bool {
        await withCheckedContinuation { continuation in
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in continuation.resume(returning: granted) }
        }
    }
    static func checkAuthorizationStatus(completion: @escaping (UNAuthorizationStatus) -> Void) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async { completion(settings.authorizationStatus) }
        }
    }
    static func authorizationStatus() async -> UNAuthorizationStatus {
        await withCheckedContinuation { continuation in
            UNUserNotificationCenter.current().getNotificationSettings { settings in
                continuation.resume(returning: settings.authorizationStatus)
            }
        }
    }
    static func schedule(for item: SupplementItem) {
        let content = UNMutableNotificationContent()
        content.title = "멍냥노트"
        content.body = "반려동물의 \(item.title) 먹일 시간이에요"
        content.sound = .default
        let trigger = UNCalendarNotificationTrigger(dateMatching: DateComponents(hour: item.reminderHour, minute: item.reminderMinute), repeats: true)
        let request = UNNotificationRequest(identifier: identifier(for: item), content: content, trigger: trigger)
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [identifier(for: item)])
        center.add(request)
    }
    static func cancel(for item: SupplementItem) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier(for: item)])
    }
}

struct SupplementCheckView: View {
    @EnvironmentObject private var themeManager: ThemeManager
    @EnvironmentObject private var petStore: PetProfileStore
    @Environment(\.scenePhase) private var scenePhase
    @State private var supplementItems = SupplementStorage.load()
    @State private var showingEditor = false
    @State private var editingItem: SupplementItem?
    @State private var newTitle = ""
    @State private var newCategory = "기타"
    @State private var newDosage = ""
    @State private var newTimeText = ""
    @State private var newMemo = ""
    @State private var reminderEnabled = false
    @State private var reminderTime = Date()
    @State private var itemToDelete: SupplementItem?
    @State private var showingDeleteAlert = false
    @State private var showingReminderAlert = false
    @AppStorage("selectedTextColor") private var selectedTextColor = AppTextColor.black.rawValue

    private var textColor: Color { themeManager.theme.palette.text }
    private var completedCount: Int { visibleItems.filter { $0.isCompleted }.count }
    private var allCompleted: Bool { !visibleItems.isEmpty && visibleItems.allSatisfy { $0.isCompleted } }
    private var visibleItems: [SupplementItem] {
        guard let id = petStore.selectedPet?.id else { return supplementItems }
        return supplementItems.filter { $0.petID == id || ($0.petID == nil && petStore.isLegacyPetSelected) }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Label("오늘의 영양제도 잊지 말고 챙겨요", systemImage: "pills.fill").font(.subheadline).foregroundStyle(.secondary)
                VStack(alignment: .leading, spacing: 12) {
                    Text("영양제 체크리스트").font(.headline).foregroundStyle(textColor)
                    ProgressView(value: Double(completedCount), total: Double(max(visibleItems.count, 1))) {
                        Text("\(visibleItems.count)개 중 \(completedCount)개 완료").font(.subheadline)
                    }
                    if allCompleted {
                        Label("오늘 영양제 완료!", systemImage: "checkmark.seal.fill").font(.subheadline.weight(.semibold)).foregroundStyle(themeManager.theme.palette.accent)
                        Text("\(petStore.selectedPet?.name ?? "반려동물")의 영양제 급여를 모두 마쳤어요").font(.caption).foregroundStyle(.secondary)
                    }
                    if visibleItems.isEmpty {
                        EmptyStateView(icon: "pills.fill", title: "등록된 영양제가 없어요", message: "먹이고 있는 영양제를 추가하면 매일 체크할 수 있어요", actionTitle: "영양제 추가하기") {
                            beginAdding()
                        }
                    } else {
                        ForEach(visibleItems) { item in supplementCard(item) }
                    }
                    Button {
                        beginAdding()
                    } label: {
                        Label("영양제 추가", systemImage: "plus.circle.fill").frame(maxWidth: .infinity, minHeight: 36)
                    }
                    .buttonStyle(.bordered)
                }
                .careCard()
            }
            .padding(16)
        }
        .background(CareBackground())
        .navigationTitle("오늘 먹인 영양제")
        .navigationBarTitleDisplayMode(.inline)
        .tint(themeManager.theme.palette.accent)
        .onAppear {
            resetSupplementItemsIfNeeded()
        }
        .onReceive(NotificationCenter.default.publisher(for: .sampleDataDidChange)) { _ in
            resetSupplementItemsIfNeeded()
            supplementItems = SupplementStorage.load()
        }
        .onChange(of: scenePhase) { _, phase in if phase == .active { resetSupplementItemsIfNeeded() } }
        .onChange(of: supplementItems) { _, items in SupplementStorage.save(items) }
        .sheet(isPresented: $showingEditor) { editorSheet }
        .alert("이 영양제를 삭제할까요?", isPresented: $showingDeleteAlert) {
            Button("취소", role: .cancel) { itemToDelete = nil }
            Button("삭제", role: .destructive) { deleteItem() }
        }
        .alert("알림 권한이 꺼져 있어요", isPresented: $showingReminderAlert) {
            Button("설정으로 이동") {
                guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
                UIApplication.shared.open(url)
            }
            Button("나중에", role: .cancel) { }
        } message: { Text("영양제 알림을 받으려면 iPhone 설정에서 멍냥노트 알림을 허용해 주세요.") }
    }

    private func supplementCard(_ item: SupplementItem) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Button { toggle(item) } label: {
                    Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "pills.fill").foregroundStyle(item.isCompleted ? themeManager.theme.palette.accent : textColor)
                    Text(item.title).font(.subheadline.weight(.semibold)).foregroundStyle(item.isCompleted ? .secondary : textColor).strikethrough(item.isCompleted)
                }.buttonStyle(.plain)
                Spacer()
                if item.isReminderEnabled { Label(String(format: "%02d:%02d", item.reminderHour, item.reminderMinute), systemImage: "bell.fill").font(.caption).foregroundStyle(themeManager.theme.palette.accent) }
            }
            HStack(spacing: 6) {
                if !item.category.isEmpty { detailTag(item.category) }
                if !item.dosage.isEmpty { detailTag(item.dosage) }
                if !item.timeText.isEmpty { detailTag(item.timeText) }
            }
            if !item.memo.isEmpty { Text("메모: \(item.memo)").font(.caption).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true) }
            HStack {
                Spacer()
                Button { beginEditing(item) } label: { Label("수정", systemImage: "pencil").font(.caption) }.buttonStyle(.borderless)
                Button(role: .destructive) { itemToDelete = item; showingDeleteAlert = true } label: { Image(systemName: "trash").font(.caption) }.buttonStyle(.borderless)
            }
        }
        .padding(12)
        .background(themeManager.theme.palette.card, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func detailTag(_ text: String) -> some View { Text(text).font(.caption2).padding(.horizontal, 7).padding(.vertical, 4).background(themeManager.theme.palette.accent.opacity(0.12), in: Capsule()) }

    private var editorSheet: some View {
        NavigationStack {
            Form {
                Section("기본 정보") {
                    TextField("영양제 이름", text: $newTitle)
                    TextField("카테고리", text: $newCategory)
                    TextField("급여량", text: $newDosage)
                    TextField("급여 시간 설명", text: $newTimeText)
                    TextField("메모", text: $newMemo)
                }
                Section("알림") {
                    Text("정해둔 시간에 영양제 급여 알림을 보내드려요. 알림은 기기 설정에서 언제든 변경할 수 있어요.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Toggle("매일 알림 받기", isOn: $reminderEnabled)
                    if reminderEnabled { DatePicker("알림 시간", selection: $reminderTime, displayedComponents: .hourAndMinute) }
                }
                Section { Button("저장", action: saveItem).disabled(newTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty) }
            }
            .navigationTitle(editingItem == nil ? "영양제 추가" : "영양제 수정")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("취소") { showingEditor = false } } }
        }
        .presentationDetents([.medium, .large])
        .onChange(of: reminderEnabled) { _, enabled in
            guard enabled, showingEditor else { return }
            Task {
                let status = await SupplementNotificationManager.authorizationStatus()
                let allowed: Bool
                if status == .notDetermined {
                    allowed = await SupplementNotificationManager.requestAuthorization()
                } else {
                    allowed = status == .authorized || status == .provisional
                }
                if !allowed {
                    await MainActor.run {
                        reminderEnabled = false
                        showingReminderAlert = true
                    }
                }
            }
        }
    }

    private func beginAdding() { editingItem = nil; newTitle = ""; newCategory = "기타"; newDosage = ""; newTimeText = ""; newMemo = ""; reminderEnabled = false; reminderTime = Date(); showingEditor = true }
    private func beginEditing(_ item: SupplementItem) { editingItem = item; newTitle = item.title; newCategory = item.category; newDosage = item.dosage; newTimeText = item.timeText; newMemo = item.memo; reminderEnabled = item.isReminderEnabled; reminderTime = Calendar.current.date(from: DateComponents(hour: item.reminderHour, minute: item.reminderMinute)) ?? Date(); showingEditor = true }

    private func saveItem() {
        let title = newTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else { return }
        let components = Calendar.current.dateComponents([.hour, .minute], from: reminderTime)
        var item = editingItem ?? SupplementItem(title: title, petID: petStore.selectedPet?.id)
        if item.petID == nil { item.petID = petStore.selectedPet?.id }
        item.title = title; item.category = newCategory; item.dosage = newDosage; item.timeText = newTimeText; item.memo = newMemo; item.isReminderEnabled = reminderEnabled; item.reminderHour = components.hour ?? 9; item.reminderMinute = components.minute ?? 0
        if let index = supplementItems.firstIndex(where: { $0.id == item.id }) { supplementItems[index] = item } else { supplementItems.append(item) }
        if reminderEnabled {
            Task {
                guard await SupplementNotificationManager.requestAuthorization() else {
                    await MainActor.run {
                        reminderEnabled = false
                        if let index = supplementItems.firstIndex(where: { $0.id == item.id }) {
                            supplementItems[index].isReminderEnabled = false
                        }
                        showingReminderAlert = true
                    }
                    return
                }
                SupplementNotificationManager.schedule(for: item)
            }
        } else { SupplementNotificationManager.cancel(for: item) }
        showingEditor = false
    }

    private func toggle(_ item: SupplementItem) {
        guard let index = supplementItems.firstIndex(where: { $0.id == item.id }) else { return }
        let wasCompleted = supplementItems[index].isCompleted
        supplementItems[index].isCompleted.toggle()
        if !wasCompleted { saveSupplementRecord(for: supplementItems[index]) }
    }

    private func saveSupplementRecord(for item: SupplementItem) {
        let title = "\(item.title) 급여 완료"
        guard let records = try? CareRecordStorage.load(), !records.contains(where: { Calendar.current.isDate($0.date, inSameDayAs: Date()) && $0.type == "영양제" && $0.title == title }) else { return }
        let memo = "급여량: \(item.dosage), 시간: \(item.timeText)"
        let record = CareRecord(type: "영양제", date: Date(), title: title, memo: memo, mealAmount: nil, walkMinutes: nil, symptoms: [], imageData: nil, petID: petStore.selectedPet?.id)
        try? CareRecordStorage.append(record)
    }

    private func deleteItem() {
        guard let item = itemToDelete else { return }
        SupplementNotificationManager.cancel(for: item)
        supplementItems.removeAll { $0.id == item.id }
        itemToDelete = nil
    }

    private func resetSupplementItemsIfNeeded() {
        let defaults = UserDefaults.standard; let today = Date()
        guard let last = defaults.object(forKey: "lastSupplementResetDate") as? Date else { defaults.set(today, forKey: "lastSupplementResetDate"); return }
        guard !Calendar.current.isDate(last, inSameDayAs: today) else { return }
        supplementItems = supplementItems.map { var item = $0; item.isCompleted = false; return item }
        SupplementStorage.save(supplementItems); defaults.set(today, forKey: "lastSupplementResetDate")
    }
}

enum SupplementStorage {
    private static let key = "supplementItems"
    static func load(from defaults: UserDefaults = .standard) -> [SupplementItem] {
        guard let data = defaults.data(forKey: key), let items = try? JSONDecoder().decode([SupplementItem].self, from: data) else { return defaultItems }
        return items.isEmpty ? defaultItems : items
    }
    static func save(_ items: [SupplementItem], to defaults: UserDefaults = .standard) { if let data = try? JSONEncoder().encode(items) { defaults.set(data, forKey: key) } }
    private static var defaultItems: [SupplementItem] {
        [SupplementItem(title: "플라그오프", category: "구강", dosage: "적정량", timeText: "식후"), SupplementItem(title: "눈물 영양제", category: "눈물", dosage: "1회분", timeText: "아침"), SupplementItem(title: "항산화제", category: "항산화", dosage: "1회분", timeText: "저녁"), SupplementItem(title: "피부 영양제", category: "피부", dosage: "1회분", timeText: "식후"), SupplementItem(title: "오메가3", category: "피부/피모", dosage: "1캡슐", timeText: "저녁 식후"), SupplementItem(title: "관절 영양제", category: "관절", dosage: "1정", timeText: "아침 식후"), SupplementItem(title: "유산균", category: "장 건강", dosage: "1포", timeText: "아침"), SupplementItem(title: "간 영양제", category: "간 건강", dosage: "1회분", timeText: "저녁")]
    }
}
