import SwiftUI

struct MonthlyReportView: View {
    @EnvironmentObject private var themeManager: ThemeManager
    @EnvironmentObject private var petStore: PetProfileStore
    @State private var month = Date()
    @State private var records: [CareRecord] = []
    @State private var weights: [WeightRecord] = []

    private var calendar: Calendar { Calendar.current }
    private var monthlyRecords: [CareRecord] {
        records.filter { calendar.isDate($0.date, equalTo: month, toGranularity: .month) && ($0.petID == petStore.selectedPet?.id || ($0.petID == nil && petStore.isLegacyPetSelected)) }
    }
    private var monthlyWeights: [WeightRecord] {
        weights.filter { calendar.isDate($0.date, equalTo: month, toGranularity: .month) && ($0.petID == petStore.selectedPet?.id || ($0.petID == nil && petStore.isLegacyPetSelected)) }.sorted { $0.date < $1.date }
    }
    private var reportItems: [(String, String, String, String)] {
        let r = monthlyRecords
        return [
            ("전체 기록", "\(r.count)", "이번 달에 남긴 기록", "note.text"),
            ("식사", "\(r.filter { $0.type == "식사" }.count)", "식사 기록", "fork.knife"),
            ("산책", "\(r.filter { $0.type == "산책" }.count)", "총 \(r.compactMap { $0.type == "산책" ? $0.walkMinutes : nil }.reduce(0, +))분", "figure.walk"),
            ("증상", "\(r.filter { $0.type == "증상" }.count)", "증상 기록", "exclamationmark.triangle.fill"),
            ("병원", "\(r.filter { $0.type == "병원" }.count)", "병원 기록", "cross.case.fill"),
            ("영양제", "\(r.filter { $0.type == "영양제" }.count)", "급여 기록", "pills.fill"),
            ("사진", "\(r.filter { $0.imageData != nil }.count)", "기록 사진", "photo"),
            ("몸무게", weightSummary, monthlyWeights.isEmpty ? "이번 달 기록" : "몸무게 변화", "scalemass.fill")
        ]
    }
    private var weightSummary: String {
        guard let first = monthlyWeights.first else { return "기록 없음" }
        guard let last = monthlyWeights.last, monthlyWeights.count > 1 else { return String(format: "%.1fkg", first.weight) }
        let change = last.weight - first.weight
        return String(format: "%.1f → %.1fkg (%+.1f)", first.weight, last.weight, change)
    }
    private var leadingType: String {
        Dictionary(grouping: monthlyRecords, by: { $0.type }).max { $0.value.count < $1.value.count }?.key ?? "아직 기록이 없어요"
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("월간 리포트").font(.largeTitle.bold())
                    Text("\(petStore.selectedPet?.name ?? "반려동물")의 한 달 케어를 정리했어요").font(.subheadline).foregroundStyle(.secondary)
                }
                HStack {
                    Button { month = calendar.date(byAdding: .month, value: -1, to: month) ?? month } label: { Image(systemName: "chevron.left") }
                    Spacer()
                    Text(month.formatted(.dateTime.year().month(.wide))).font(.headline)
                    Spacer()
                    Button { month = calendar.date(byAdding: .month, value: 1, to: month) ?? month } label: { Image(systemName: "chevron.right") }
                }
                .careCard()
                if monthlyRecords.isEmpty {
                    EmptyStateView(icon: "chart.bar.doc.horizontal", title: "이번 달 기록이 아직 없어요", message: "식사, 산책, 증상 기록이 쌓이면 월간 리포트가 만들어져요")
                }
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(Array(reportItems.enumerated()), id: \.offset) { _, item in
                        VStack(alignment: .leading, spacing: 7) {
                            Label(item.0, systemImage: item.3).font(.subheadline.weight(.semibold))
                            Text(item.1).font(.title3.bold())
                            Text(item.2).font(.caption).foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .careCard()
                    }
                }
                VStack(alignment: .leading, spacing: 6) {
                    Text("이번 달 인사이트").font(.headline)
                    Text(insightText).font(.subheadline).foregroundStyle(.secondary)
                }
                .careCard()
            }
            .padding(16)
        }
        .background(CareBackground())
        .navigationTitle("월간 리포트")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            records = (try? CareRecordStorage.load()) ?? []
            weights = WeightRecordStorage.load()
        }
        .onReceive(NotificationCenter.default.publisher(for: .sampleDataDidChange)) { _ in
            month = Date()
            records = (try? CareRecordStorage.load()) ?? []
            weights = WeightRecordStorage.load()
        }
    }

    private var insightText: String {
        if monthlyRecords.filter({ $0.type == "증상" }).count >= 3 { return "증상 기록이 여러 번 남아 있어요. 반복된다면 병원 상담을 고려해 보세요." }
        if monthlyRecords.contains(where: { $0.type == "산책" }) { return "이번 달 산책 기록이 꾸준히 쌓이고 있어요." }
        if monthlyRecords.contains(where: { $0.type == "영양제" }) { return "영양제 급여 기록이 남아 있어 관리 흐름을 확인하기 좋아요." }
        return "조금씩 기록을 쌓으면 생활 패턴을 더 잘 볼 수 있어요."
    }
}
