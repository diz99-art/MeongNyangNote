import SwiftUI
import UserNotifications

struct CareItem: Identifiable, Codable, Equatable {
    var id = UUID()
    var title: String
    var isCompleted = false
    var petID: UUID? = nil
    var reminderHour: Int? = nil
    var reminderMinute: Int? = nil
    var isReminderEnabled = false

    // 기존에 저장된 항목도 안전하게 불러올 수 있도록 기본값을 사용합니다.
    enum CodingKeys: String, CodingKey { case id, title, isCompleted, reminderHour, reminderMinute, isReminderEnabled, petID }

    init(id: UUID = UUID(), title: String, isCompleted: Bool = false,
         reminderHour: Int? = nil, reminderMinute: Int? = nil, isReminderEnabled: Bool = false, petID: UUID? = nil) {
        self.id = id
        self.title = title
        self.isCompleted = isCompleted
        self.reminderHour = reminderHour
        self.reminderMinute = reminderMinute
        self.isReminderEnabled = isReminderEnabled
        self.petID = petID
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        id = try values.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        title = try values.decode(String.self, forKey: .title)
        isCompleted = try values.decodeIfPresent(Bool.self, forKey: .isCompleted) ?? false
        reminderHour = try values.decodeIfPresent(Int.self, forKey: .reminderHour)
        reminderMinute = try values.decodeIfPresent(Int.self, forKey: .reminderMinute)
        isReminderEnabled = try values.decodeIfPresent(Bool.self, forKey: .isReminderEnabled) ?? false
        petID = try values.decodeIfPresent(UUID.self, forKey: .petID)
    }
}

enum CareReminderManager {
    private static func identifier(for item: CareItem) -> String { "careReminder-\(item.id.uuidString)" }

    static func requestAuthorization() async -> Bool {
        await withCheckedContinuation { continuation in
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
                continuation.resume(returning: granted)
            }
        }
    }

    static func schedule(for item: CareItem, at date: Date) {
        let content = UNMutableNotificationContent()
        content.title = "멍냥노트"
        content.body = "반려동물의 \(item.title) 시간이에요"
        content.sound = .default

        let components = Calendar.current.dateComponents([.hour, .minute], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(identifier: identifier(for: item), content: content, trigger: trigger)
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [identifier(for: item)])
        center.add(request)
    }

    static func cancel(for item: CareItem) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier(for: item)])
    }
}

struct HomeView: View {
    @State private var showPetManagement = false
    @State private var showWeightRecord = false
    @EnvironmentObject private var themeManager: ThemeManager
    @EnvironmentObject private var petStore: PetProfileStore
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var careItems = CareItemStorage.load()
    @State private var newItemTitle = ""
    @State private var isAddingCareItem = false
    @State private var isShowingTodayMemo = false
    @State private var todayMemo = ""
    @State private var isTodayMemoPinned = false
    @State private var isEditingTodayMemo = false
    @State private var isCompletedItemsExpanded = false
    @State private var showMemoSavedAlert = false
    @State private var reminderItem: CareItem?
    @State private var reminderTime = Date()
    @State private var reminderEnabled = false
    @State private var showReminderAlert = false
    @State private var reminderAlertMessage = ""
    @State private var isWalking = false
    @State private var walkStartDate: Date?
    @State private var elapsedSeconds = 0
    @State private var showWalkSavedAlert = false
    @State private var showWalkTimerSheet = false
    private let walkTimer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    @AppStorage("selectedTextColor") private var selectedTextColor = AppTextColor.black.rawValue

    private var textColor: Color { themeManager.theme.palette.text }
    private var selectedPetName: String {
        let name = petStore.selectedPet?.name.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return name.isEmpty ? "이름 입력" : name
    }
    private var selectedPetAge: String? {
        let age = petStore.selectedPet?.ageText.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return age.isEmpty ? nil : age
    }

    private var completedCount: Int {
        careItems.filter { $0.isCompleted }.count
    }

    private var isCareCompleted: Bool {
        !careItems.isEmpty && careItems.allSatisfy { $0.isCompleted }
    }

    private var trimmedTitle: String {
        newItemTitle.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                homeHeader

                if isShowingTodayMemo || isTodayMemoPinned {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Label("오늘 한 줄 메모", systemImage: "note.text")
                                .font(.headline)
                            Spacer()
                            Toggle(isOn: $isTodayMemoPinned) {
                                Label("홈에 고정", systemImage: isTodayMemoPinned ? "pin.fill" : "pin")
                                    .font(.caption)
                            }
                            .toggleStyle(.switch)
                            .onChange(of: isTodayMemoPinned) { _, pinned in
                                UserDefaults.standard.set(pinned, forKey: "todayMemoPinned")
                                if pinned {
                                    isShowingTodayMemo = true
                                } else {
                                    isEditingTodayMemo = false
                                    isShowingTodayMemo = false
                                }
                            }
                            if isTodayMemoPinned && !isEditingTodayMemo {
                                Button {
                                    isEditingTodayMemo = true
                                } label: {
                                    Image(systemName: "pencil")
                                        .font(.caption)
                                        .padding(6)
                                        .background(themeManager.theme.palette.accent.opacity(0.12), in: Circle())
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel("메모 편집")
                            }
                        }
                        if isTodayMemoPinned && !isEditingTodayMemo {
                            Text(todayMemo.isEmpty ? "아직 메모가 없어요" : todayMemo)
                                .font(.subheadline)
                                .foregroundStyle(todayMemo.isEmpty ? .secondary : textColor)
                                .fixedSize(horizontal: false, vertical: true)
                        } else {
                            ZStack(alignment: .topLeading) {
                                TextEditor(text: $todayMemo)
                                    .frame(minHeight: 56, maxHeight: 100)
                                    .scrollContentBackground(.hidden)
                                if todayMemo.isEmpty {
                                    Text("오늘 \(selectedPetName) 상태를 한 줄로 적어보세요")
                                        .foregroundStyle(.secondary)
                                        .padding(.top, 8)
                                        .padding(.leading, 5)
                                        .allowsHitTesting(false)
                                }
                            }
                        }
                        if !isTodayMemoPinned || isEditingTodayMemo {
                            HStack {
                            Button {
                                UserDefaults.standard.set(todayMemo, forKey: "todayMemo")
                                isEditingTodayMemo = false
                                withAnimation { isShowingTodayMemo = false }
                                showMemoSavedAlert = true
                            } label: {
                                Label("저장", systemImage: "checkmark.circle.fill")
                            }
                            .buttonStyle(.borderedProminent)
                            Button("취소") {
                                // 저장하지 않은 입력은 버리고 마지막 저장값으로 돌아갑니다.
                                todayMemo = UserDefaults.standard.string(forKey: "todayMemo") ?? ""
                                isEditingTodayMemo = false
                                withAnimation { isShowingTodayMemo = isTodayMemoPinned }
                            }
                            .buttonStyle(.bordered)
                            }
                        }
                    }
                    .careCard()
                }

                careCard

            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(CareBackground())
        .navigationTitle("멍냥노트")
        .toolbar(.hidden, for: .navigationBar)
        .scrollDismissesKeyboard(.interactively)
        .alert("메모가 저장되었습니다.", isPresented: $showMemoSavedAlert) {
            Button("확인", role: .cancel) { }
        }
        .alert("알림 설정", isPresented: $showReminderAlert) {
            Button("확인", role: .cancel) { }
        } message: {
            Text(reminderAlertMessage)
        }
        .alert("산책 기록이 저장되었습니다.", isPresented: $showWalkSavedAlert) {
            Button("확인", role: .cancel) { }
        }
        .onReceive(walkTimer) { now in
            resetCareItemsIfNeeded()
            guard isWalking, let start = walkStartDate else { return }
            elapsedSeconds = max(0, Int(now.timeIntervalSince(start)))
        }
        .sheet(item: $reminderItem) { _ in
            ReminderSettingView(item: $reminderItem, time: $reminderTime, isEnabled: $reminderEnabled,
                                onSave: saveReminder, onDisable: disableReminder)
                .environmentObject(themeManager)
        }
        .sheet(isPresented: $showPetManagement) {
            NavigationStack { PetManagementView() }
                .environmentObject(themeManager)
                .environmentObject(petStore)
        }
        .sheet(isPresented: $showWeightRecord) {
            NavigationStack { WeightRecordView() }
                .environmentObject(themeManager)
                .environmentObject(petStore)
        }
        .sheet(isPresented: $showWalkTimerSheet) {
            WalkTimerSheetView(isWalking: $isWalking, elapsedSeconds: $elapsedSeconds,
                               onStart: startWalk, onStop: stopWalk, onReset: resetWalk,
                               onSave: saveWalkRecord, petName: selectedPetName)
                .environmentObject(themeManager)
        }
        .onAppear {
            resetCareItemsIfNeeded()
            careItems = CareItemStorage.load(for: petStore.selectedPet?.id)
            todayMemo = UserDefaults.standard.string(forKey: "todayMemo") ?? ""
            isTodayMemoPinned = UserDefaults.standard.bool(forKey: "todayMemoPinned")
            isShowingTodayMemo = isTodayMemoPinned
        }
        .onReceive(NotificationCenter.default.publisher(for: .sampleDataDidChange)) { _ in
            resetCareItemsIfNeeded()
            careItems = CareItemStorage.load(for: petStore.selectedPet?.id)
            todayMemo = UserDefaults.standard.string(forKey: "todayMemo") ?? ""
            isTodayMemoPinned = UserDefaults.standard.bool(forKey: "todayMemoPinned")
            isShowingTodayMemo = isTodayMemoPinned
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                resetCareItemsIfNeeded()
                careItems = CareItemStorage.load(for: petStore.selectedPet?.id)
            }
        }
        .onChange(of: petStore.selectedPetID) { _, id in
            careItems = CareItemStorage.load(for: id)
        }
        .onChange(of: careItems) { _, items in
            CareItemStorage.save(items, for: petStore.selectedPet?.id)
            if !isCareCompleted {
                isCompletedItemsExpanded = false
            }
        }
    }

    private var homeHeader: some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: 8) {
                    homeIntroduction
                    profileControls.frame(maxWidth: .infinity, alignment: .trailing)
                }
            } else {
                HStack(alignment: .top, spacing: 12) {
                    homeIntroduction.frame(maxWidth: .infinity, alignment: .leading)
                    profileControls
                }
            }
        }
    }

    private var homeIntroduction: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("멍냥노트")
                .font(.title.bold())
                .foregroundStyle(textColor)
            Text("우리 아이의 하루를 기록해요")
                .font(.subheadline)
                .foregroundStyle(themeManager.theme.palette.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
            Button {
                withAnimation {
                    isShowingTodayMemo = isTodayMemoPinned ? true : !isShowingTodayMemo
                }
            } label: {
                Label("오늘 한 줄 메모", systemImage: "note.text")
                    .font(.caption)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .foregroundStyle(themeManager.theme.palette.accent)
                    .background(themeManager.theme.palette.accent.opacity(0.12), in: Capsule())
            }
            .buttonStyle(.plain)
        }
    }

    private var profileControls: some View {
        HStack(alignment: .top, spacing: 8) {
            VStack(alignment: .trailing, spacing: 4) {
                HStack(spacing: 4) {
                headerAction(isWalking ? compactWalkTime : "산책",
                                 icon: isWalking ? "stopwatch.fill" : "figure.walk",
                                 accessibility: "산책 타이머", timer: true) {
                    showWalkTimerSheet = true
                    }
                    headerAction("관리", icon: "gearshape.fill", accessibility: "반려동물 관리") {
                        showPetManagement = true
                    }
                }
                HStack(spacing: 4) {
                    headerAction("몸무게", icon: "scalemass.fill", accessibility: "몸무게 기록") {
                        showWeightRecord = true
                    }
                    Color.clear
                        .frame(width: 52, height: 56)
                        .accessibilityHidden(true)
                }
            }
            NavigationLink {
                DogProfileView()
            } label: {
                VStack(spacing: 3) {
                    DogProfileImage(size: 56)
                        .overlay(Circle().stroke(themeManager.theme.palette.accent.opacity(0.2), lineWidth: 1))
                    Text(selectedPetName)
                        .font(.caption.bold())
                        .foregroundStyle(textColor)
                    if let selectedPetAge {
                        Text(selectedPetAge)
                            .font(.caption2)
                            .foregroundStyle(themeManager.theme.palette.secondaryText)
                    }
                }
                .multilineTextAlignment(.center)
                .frame(width: 62)
                .fixedSize(horizontal: false, vertical: true)
            }
            .buttonStyle(.plain)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("\(selectedPetName), 프로필 보기")
        }
    }

    private func headerAction(_ title: String, icon: String, accessibility: String,
                              timer: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 3) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .frame(width: 36, height: 36)
                    .background(themeManager.theme.palette.card, in: Circle())
                    .shadow(color: .black.opacity(0.025), radius: 3, y: 1)
                Text(title)
                    .font(.caption2)
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .frame(height: 18)
            }
            .foregroundStyle(themeManager.theme.palette.accent)
            .frame(width: 52)
            .frame(minHeight: 56)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibility)
        .accessibilityValue(timer && isWalking ? compactWalkTime : "")
    }

    private func addCareItem() {
        let title = trimmedTitle
        guard !title.isEmpty else { return }
        careItems.append(CareItem(title: title, petID: petStore.selectedPet?.id))
        newItemTitle = ""
        isAddingCareItem = false
    }

    private var addCareButton: some View {
        Button {
            isAddingCareItem = true
        } label: {
            Label("케어 추가", systemImage: "plus.circle.fill")
                .font(.caption2.weight(.semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.75)
                .padding(.horizontal, 8)
                .frame(minHeight: 30)
        }
        .buttonStyle(.plain)
        .foregroundStyle(themeManager.theme.palette.accent)
        .background(themeManager.theme.palette.accent.opacity(0.12), in: Capsule())
        .accessibilityLabel("케어 항목 추가")
    }

    private var addRecordButton: some View {
        NavigationLink {
            AddRecordView()
        } label: {
            Label("기록", systemImage: "square.and.pencil")
                .font(.caption2.weight(.semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .padding(.horizontal, 8)
                .frame(minHeight: 30)
        }
        .buttonStyle(.plain)
        .foregroundStyle(themeManager.theme.palette.accent)
        .background(themeManager.theme.palette.accent.opacity(0.12), in: Capsule())
        .accessibilityLabel("기록추가")
    }

    private var careCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .center, spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: "pawprint.fill")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(themeManager.theme.palette.accent)
                        .frame(width: 28, height: 28)
                        .background(themeManager.theme.palette.accent.opacity(0.12), in: Circle())
                    Text("오늘의 케어")
                        .font(.headline)
                }
                Spacer()
                HStack(spacing: 6) {
                    addCareButton
                    addRecordButton
                }
            }
            Text("\(careItems.count)개 중 \(completedCount)개 완료")
                .font(.caption)
                .foregroundStyle(.secondary)
                    ProgressView(value: Double(completedCount), total: Double(max(careItems.count, 1)))
                        .tint(themeManager.theme.palette.accent)
                        .accessibilityLabel("오늘의 케어 진행률")
                        .accessibilityValue("\(careItems.count)개 중 \(completedCount)개 완료")

                    if isCareCompleted {
                        Label("오늘 케어 완료!", systemImage: "checkmark.seal.fill")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(themeManager.theme.palette.accent)
                        Text("\(selectedPetName)의 하루 케어를 모두 마쳤어요")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

            if careItems.isEmpty {
                Text("작은 케어부터 하나씩 추가해보세요")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            if !isCareCompleted || isCompletedItemsExpanded {
                ForEach($careItems) { $item in
                HStack {
                    Button {
                        item.isCompleted.toggle()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                                .font(.body)
                            Text(item.title)
                                .font(.subheadline)
                                .strikethrough(item.isCompleted)
                                .foregroundStyle(item.isCompleted ? .secondary : textColor)
                            Spacer()
                        }
                        .frame(minHeight: 36)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.borderless)
                    .accessibilityValue(item.isCompleted ? "완료" : "미완료")
                    Button {
                        configureReminder(for: item)
                    } label: {
                        Image(systemName: item.isReminderEnabled ? "bell.fill" : "bell")
                            .font(.caption)
                            .foregroundStyle(item.isReminderEnabled ? themeManager.theme.palette.accent : .secondary)
                            .frame(width: 32, height: 36)
                    }
                    .buttonStyle(.borderless)
                    .accessibilityLabel("\(item.title) 알림 시간 설정")
                    Button(role: .destructive) {
                        let id = item.id
                        CareReminderManager.cancel(for: item)
                        careItems.removeAll { $0.id == id }
                    } label: {
                        Image(systemName: "trash")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .frame(minWidth: 44, minHeight: 44)
                    }
                    .buttonStyle(.borderless)
                    .accessibilityLabel("\(item.title) 삭제")
                }
                Divider().opacity(0.35)
                }
            }

            if isCareCompleted {
                    Button {
                        withAnimation(.easeInOut) {
                            isCompletedItemsExpanded.toggle()
                        }
                    } label: {
                        Label(isCompletedItemsExpanded ? "완료한 항목 접기" : "완료한 항목 보기",
                              systemImage: isCompletedItemsExpanded ? "chevron.up" : "chevron.down")
                            .font(.caption.weight(.semibold))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .foregroundStyle(themeManager.theme.palette.accent)
                            .background(themeManager.theme.palette.accent.opacity(0.12), in: Capsule())
                    }
                    .buttonStyle(.plain)
            }

            if isAddingCareItem {
                TextField("케어 항목 추가", text: $newItemTitle)
                    .textFieldStyle(.roundedBorder)
                    .submitLabel(.done)
                    .onSubmit { addCareItem() }
                HStack {
                    Button("추가", action: addCareItem)
                        .buttonStyle(.borderedProminent)
                        .disabled(trimmedTitle.isEmpty)
                    Button("취소") {
                        newItemTitle = ""
                        isAddingCareItem = false
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
        .careCard()
    }

    private var walkTimerCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("산책 타이머", systemImage: "figure.walk")
                .font(.headline)
            if isWalking {
                Text(formattedElapsedTime)
                    .font(.title2.monospacedDigit().weight(.semibold))
                Button("산책 종료", action: finishWalk)
                    .buttonStyle(.borderedProminent)
                    .tint(themeManager.theme.palette.accent)
            } else {
                Text("산책을 시작해보세요")
                    .font(.subheadline).foregroundStyle(.secondary)
                Button("산책 시작", action: startWalk)
                    .buttonStyle(.borderedProminent)
                    .tint(themeManager.theme.palette.accent)
            }
        }
        .careCard()
    }

    private var formattedElapsedTime: String {
        String(format: "%02d:%02d:%02d", elapsedSeconds / 3600, (elapsedSeconds % 3600) / 60, elapsedSeconds % 60)
    }

    private var compactWalkTime: String {
        if elapsedSeconds >= 3600 { return formattedElapsedTime }
        return String(format: "%02d:%02d", elapsedSeconds / 60, elapsedSeconds % 60)
    }

    private func startWalk() {
        walkStartDate = Date()
        elapsedSeconds = 0
        isWalking = true
    }

    private func finishWalk() {
        let minutes = max(1, Int(ceil(Double(elapsedSeconds) / 60.0)))
        let record = CareRecord(type: "산책", date: Date(), title: "산책 완료", memo: "산책 타이머로 기록됨", mealAmount: nil, walkMinutes: minutes, symptoms: [], petID: petStore.selectedPet?.id)
        try? CareRecordStorage.append(record)
        isWalking = false
        walkStartDate = nil
        elapsedSeconds = 0
        showWalkSavedAlert = true
    }

    private func stopWalk() {
        guard isWalking else { return }
        isWalking = false
        walkStartDate = nil
    }

    private func resetWalk() {
        isWalking = false
        walkStartDate = nil
        elapsedSeconds = 0
    }

    private func saveWalkRecord() {
        guard elapsedSeconds > 0 else { return }
        let minutes = max(1, Int(ceil(Double(elapsedSeconds) / 60.0)))
        let record = CareRecord(type: "산책", date: Date(), title: "산책 완료", memo: "산책 타이머로 기록됨", mealAmount: nil, walkMinutes: minutes, symptoms: [], imageData: nil, petID: petStore.selectedPet?.id)
        try? CareRecordStorage.append(record)
        resetWalk()
        showWalkSavedAlert = true
    }

    private func configureReminder(for item: CareItem) {
        reminderItem = item
        reminderEnabled = item.isReminderEnabled
        if let hour = item.reminderHour, let minute = item.reminderMinute {
            reminderTime = Calendar.current.date(from: DateComponents(hour: hour, minute: minute)) ?? Date()
        } else {
            reminderTime = Date()
        }
    }

    private func saveReminder() {
        guard let selected = reminderItem else { return }
        if reminderEnabled {
            Task {
                guard await CareReminderManager.requestAuthorization() else {
                    await MainActor.run {
                        reminderEnabled = false
                        reminderAlertMessage = "알림 권한이 꺼져 있어요. iPhone 설정에서 알림을 허용해주세요."
                        showReminderAlert = true
                    }
                    return
                }
                let components = Calendar.current.dateComponents([.hour, .minute], from: reminderTime)
                updateReminder(for: selected.id, hour: components.hour, minute: components.minute, enabled: true)
                if let updated = careItems.first(where: { $0.id == selected.id }) {
                    CareReminderManager.schedule(for: updated, at: reminderTime)
                }
                reminderItem = nil
            }
        } else {
            disableReminder()
        }
    }

    private func disableReminder() {
        guard let selected = reminderItem else { return }
        CareReminderManager.cancel(for: selected)
        updateReminder(for: selected.id, hour: nil, minute: nil, enabled: false)
        reminderItem = nil
    }

    private func updateReminder(for id: UUID, hour: Int?, minute: Int?, enabled: Bool) {
        guard let index = careItems.firstIndex(where: { $0.id == id }) else { return }
        careItems[index].reminderHour = hour
        careItems[index].reminderMinute = minute
        careItems[index].isReminderEnabled = enabled
    }

    private func resetCareItemsIfNeeded() {
        let defaults = UserDefaults.standard
        let today = Date()
        guard let lastResetDate = defaults.object(forKey: "lastCareResetDate") as? Date else {
            defaults.set(today, forKey: "lastCareResetDate")
            return
        }
        guard !Calendar.current.isDate(lastResetDate, inSameDayAs: today) else { return }

        // 날짜가 바뀌면 모든 아이의 완료 상태를 초기화하고 선택된 아이만 표시합니다.
        let resetItems = CareItemStorage.load().map { item in
            var resetItem = item
            resetItem.isCompleted = false
            return resetItem
        }
        CareItemStorage.save(resetItems)
        careItems = CareItemStorage.load(for: petStore.selectedPet?.id)
        defaults.set(today, forKey: "lastCareResetDate")
        isCompletedItemsExpanded = false
    }
}

private struct WalkTimerSheetView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var themeManager: ThemeManager
    @Binding var isWalking: Bool
    @Binding var elapsedSeconds: Int
    let onStart: () -> Void
    let onStop: () -> Void
    let onReset: () -> Void
    let onSave: () -> Void
    let petName: String

    var body: some View {
        NavigationStack {
            VStack(spacing: 22) {
                VStack(spacing: 6) {
                    Text("산책 타이머").font(.title2.bold())
                    Text("\(petName)와 산책 시간을 기록해요").font(.subheadline).foregroundStyle(.secondary)
                }
                Text(String(format: "%02d:%02d:%02d", elapsedSeconds / 3600, (elapsedSeconds % 3600) / 60, elapsedSeconds % 60))
                    .font(.system(size: 42, weight: .semibold, design: .monospaced))
                    .foregroundStyle(themeManager.theme.palette.text)
                HStack(spacing: 10) {
                    Button("시작", action: onStart).buttonStyle(.borderedProminent).tint(themeManager.theme.palette.accent).disabled(isWalking)
                    Button("정지", action: onStop).buttonStyle(.bordered).disabled(!isWalking)
                    Button("초기화", action: onReset).buttonStyle(.bordered).disabled(isWalking && elapsedSeconds == 0)
                }
                if !isWalking && elapsedSeconds > 0 {
                    Button("산책 기록 저장", action: onSave)
                        .buttonStyle(.borderedProminent)
                        .tint(themeManager.theme.palette.accent)
                }
                Spacer()
            }
            .padding(24)
            .navigationTitle("산책 타이머")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("닫기") { dismiss() } } }
        }
        .presentationDetents([.medium])
    }
}

private struct ReminderSettingView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var themeManager: ThemeManager
    let item: Binding<CareItem?>
    @Binding var time: Date
    @Binding var isEnabled: Bool
    let onSave: () -> Void
    let onDisable: () -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section("케어 항목") { Text(item.wrappedValue?.title ?? "") }
                Section("알림 시간") {
                    DatePicker("시간", selection: $time, displayedComponents: .hourAndMinute)
                    Toggle("매일 알림 받기", isOn: $isEnabled)
                }
                Section {
                    Button("저장") { onSave() }
                        .foregroundStyle(themeManager.theme.palette.accent)
                    Button("알림 끄기", role: .destructive) { onDisable() }
                }
            }
            .navigationTitle("알림 시간 설정")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("닫기") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium])
    }
}

// JSON 데이터로 변환해 UserDefaults에 저장합니다.
enum CareItemStorage {
    private static let key = "careItems"

    static func load(from defaults: UserDefaults = .standard) -> [CareItem] {
        if let data = defaults.data(forKey: key),
           let items = try? JSONDecoder().decode([CareItem].self, from: data) {
            // 저장된 빈 배열도 그대로 불러옵니다.
            return items
        }

        // 첫 실행이거나 저장 데이터를 읽을 수 없으면 기본 목록을 표시합니다.
        return [
            CareItem(title: "아침 식사"),
            CareItem(title: "저녁 식사"),
            CareItem(title: "산책"),
            CareItem(title: "오메가3"),
            CareItem(title: "관절 영양제"),
            CareItem(title: "눈물 상태 확인")
        ]
    }

    static func load(for petID: UUID?, from defaults: UserDefaults = .standard) -> [CareItem] {
        let items = load(from: defaults)
        guard let petID else { return items }
        return items.filter { $0.petID == nil || $0.petID == petID }
    }

    static func save(_ items: [CareItem], to defaults: UserDefaults = .standard) {
        guard let data = try? JSONEncoder().encode(items) else { return }
        defaults.set(data, forKey: key)
    }

    static func save(_ items: [CareItem], for petID: UUID?, to defaults: UserDefaults = .standard) {
        guard let petID else { save(items, to: defaults); return }
        var all = load(from: defaults)
        all.removeAll { $0.petID == petID || $0.petID == nil }
        all.append(contentsOf: items.map { item in var copy = item; copy.petID = petID; return copy })
        save(all, to: defaults)
    }
}
