import SwiftUI
import Charts

struct WeightRecordView: View {
    @EnvironmentObject private var themeManager: ThemeManager
    @EnvironmentObject private var petStore: PetProfileStore
    @Environment(\.dismiss) private var dismiss
    @State private var weightRecords = WeightRecordStorage.load()
    @State private var weightText = ""
    @State private var weightDate = Date()
    @State private var weightMemo = ""
    @State private var showingWeightAlert = false
    @State private var showingWeightSaveError = false

    private var textColor: Color { themeManager.theme.palette.text }
    private var visibleWeightRecords: [WeightRecord] {
        guard let selectedID = petStore.selectedPet?.id else { return weightRecords }
        return weightRecords.filter { $0.petID == selectedID || ($0.petID == nil && petStore.isLegacyPetSelected) }
    }


    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("\(petStore.selectedPet?.name ?? "우리 아이")의 몸무게 변화를 기록해요")
                    .font(.subheadline).foregroundStyle(textColor)
                weightCard
            }
            .padding(16)
        }
        .background(CareBackground())
        .navigationTitle("몸무게 기록")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { ToolbarItem(placement: .cancellationAction) { Button("닫기") { dismiss() } } }
        .onAppear { weightRecords = WeightRecordStorage.load() }
        .onReceive(NotificationCenter.default.publisher(for: .sampleDataDidChange)) { _ in
            weightRecords = WeightRecordStorage.load()
        }
        .alert("몸무게를 입력해주세요", isPresented: $showingWeightAlert) {
            Button("확인", role: .cancel) { }
        }
        .alert("몸무게 기록을 저장하지 못했어요", isPresented: $showingWeightSaveError) {
            Button("확인", role: .cancel) { }
        } message: {
            Text("입력한 내용은 유지했어요. 기존 기록 데이터를 확인한 뒤 다시 시도해 주세요.")
        }
    }

    private var weightCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("몸무게 기록", systemImage: "scalemass.fill")
                .font(.headline).foregroundStyle(textColor)
            HStack {
                TextField("몸무게 (kg)", text: $weightText)
                    .keyboardType(.decimalPad)
                    .textFieldStyle(.roundedBorder)
                DatePicker("날짜", selection: $weightDate, displayedComponents: .date)
                    .labelsHidden()
            }
            TextField("메모를 입력하세요", text: $weightMemo)
                .textFieldStyle(.roundedBorder)
            Button("몸무게 저장") { saveWeight() }
                .buttonStyle(.borderedProminent)
                .tint(themeManager.theme.palette.accent)

            if visibleWeightRecords.count >= 2 {
                Chart(visibleWeightRecords.sorted { $0.date < $1.date }) { record in
                    LineMark(x: .value("날짜", record.date), y: .value("몸무게", record.weight))
                        .foregroundStyle(themeManager.theme.palette.accent)
                    PointMark(x: .value("날짜", record.date), y: .value("몸무게", record.weight))
                        .foregroundStyle(themeManager.theme.palette.accent)
                }
                .frame(height: 160)
                .chartYAxisLabel("kg")
            } else {
                Text("몸무게 기록이 쌓이면 그래프가 표시돼요")
                    .font(.caption).foregroundStyle(.secondary)
            }

            if !visibleWeightRecords.isEmpty {
                Divider()
                ForEach(visibleWeightRecords.sorted { $0.date > $1.date }) { record in
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 3) {
                            Text("\(record.weight, specifier: "%.1f")kg")
                                .font(.subheadline.weight(.semibold)).foregroundStyle(textColor)
                            Text(record.date, format: .dateTime.year().month().day())
                                .font(.caption).foregroundStyle(.secondary)
                            if !record.memo.isEmpty { Text(record.memo).font(.caption).foregroundStyle(.secondary) }
                        }
                        Spacer()
                        Button(role: .destructive) {
                            weightRecords.removeAll { $0.id == record.id }
                            WeightRecordStorage.save(weightRecords)
                        } label: {
                            Image(systemName: "trash").font(.caption)
                        }
                        .buttonStyle(.borderless)
                    }
                }
            }
        }
        .careCard()
    }

    private func saveWeight() {
        guard let weight = Double(weightText.replacingOccurrences(of: ",", with: ".")),
              weight.isFinite, weight > 0 else {
            showingWeightAlert = true
            return
        }
        let record = WeightRecord(date: weightDate, weight: weight, memo: weightMemo, petID: petStore.selectedPet?.id)
        do {
            try WeightRecordStorage.appendWithCareRecord(record)
            weightRecords = WeightRecordStorage.load()
            weightText = ""
            weightMemo = ""
        } catch {
            showingWeightSaveError = true
        }
    }

}

struct WeightRecord: Identifiable, Codable, Equatable {
    var id = UUID()
    var date: Date
    var weight: Double
    var memo: String
    var petID: UUID? = nil
}

enum WeightRecordStorage {
    private static let key = "weightRecords"
    static func load(from defaults: UserDefaults = .standard) -> [WeightRecord] {
        guard let data = defaults.data(forKey: key), let records = try? JSONDecoder().decode([WeightRecord].self, from: data) else { return [] }
        return records
    }
    // 새 기록 추가 시에만 연동하며 조회나 삭제에서는 호출하지 않습니다.
    static func appendWithCareRecord(_ record: WeightRecord, to defaults: UserDefaults = .standard) throws {
        let existingData = defaults.data(forKey: key)
        var records = try existingData.map { try JSONDecoder().decode([WeightRecord].self, from: $0) } ?? []
        records.append(record)
        // 인코딩 및 기존 기록 읽기가 실패하면 어느 저장소도 변경하지 않습니다.
        let weightData = try JSONEncoder().encode(records)
        let amount = record.weight.formatted(.number.locale(Locale(identifier: "en_US_POSIX")).precision(.fractionLength(0...3)))
        let memo = "몸무게: \(amount)kg" + (record.memo.isEmpty ? "" : "\n" + record.memo)
        let careRecord = CareRecord(type: "몸무게", date: record.date, title: "몸무게 기록", memo: memo,
                                    mealAmount: nil, walkMinutes: nil, symptoms: [], imageData: nil, petID: record.petID)
        try CareRecordStorage.append(careRecord, to: defaults)
        defaults.set(weightData, forKey: key)
    }

    static func save(_ records: [WeightRecord], to defaults: UserDefaults = .standard) {
        guard let data = try? JSONEncoder().encode(records) else { return }
        defaults.set(data, forKey: key)
    }
}
