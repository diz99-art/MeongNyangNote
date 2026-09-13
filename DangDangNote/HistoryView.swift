import SwiftUI
import UIKit

struct HistoryView: View {
    @EnvironmentObject private var themeManager: ThemeManager
    @EnvironmentObject private var petStore: PetProfileStore
    @State private var records: [CareRecord] = []
    @State private var selectedDate = Date()
    @State private var isDateFilterEnabled = false
    @State private var displayedMonth = Date()
    @State private var recordToDelete: CareRecord?
    @State private var showingDeleteConfirmation = false
    @State private var errorMessage: String?
    @State private var showingAddRecord = false
    @AppStorage("selectedTextColor") private var selectedTextColor = AppTextColor.black.rawValue

    private var textColor: Color { themeManager.theme.palette.text }
    private var selectedPetName: String {
        let name = petStore.selectedPet?.name.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return name.isEmpty ? "우리 아이" : name
    }

    private var filteredRecords: [CareRecord] {
        records.filter { record in
            let matchesPet = record.petID == petStore.selectedPet?.id || (record.petID == nil && petStore.isLegacyPetSelected)
            let matchesDate = !isDateFilterEnabled || Calendar.current.isDate(record.date, inSameDayAs: selectedDate)
            return matchesPet && matchesDate
        }
    }

    var body: some View {
        ZStack {
            CareBackground()
            VStack(spacing: 6) {
            VStack(alignment: .leading, spacing: 2) {
                Text("기록")
                    .font(.largeTitle.bold())
                    .foregroundStyle(textColor)
                Text("\(selectedPetName)의 하루 기록을 모아봤어요")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
            .padding(.top, 10)

            HStack {
                Spacer()
                NavigationLink {
                    MonthlyReportView()
                } label: {
                    Label("월간 리포트", systemImage: "chart.bar.doc.horizontal")
                        .font(.subheadline.weight(.semibold))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(themeManager.theme.palette.accent.opacity(0.12), in: Capsule())
                }
                .buttonStyle(.plain)
                NavigationLink {
                    PhotoAlbumView()
                } label: {
                    Label("사진 앨범", systemImage: "photo.on.rectangle.angled")
                        .font(.subheadline.weight(.semibold))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(themeManager.theme.palette.accent.opacity(0.12), in: Capsule())
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Label(monthTitle, systemImage: "calendar")
                        .font(.headline)
                    Spacer()
                    Button {
                        moveMonth(by: -1)
                    } label: {
                        Image(systemName: "chevron.left")
                    }
                    .buttonStyle(.borderless)
                    .accessibilityLabel("이전 달")
                    Button {
                        moveMonth(by: 1)
                    } label: {
                        Image(systemName: "chevron.right")
                    }
                    .buttonStyle(.borderless)
                    .accessibilityLabel("다음 달")
                    if isDateFilterEnabled {
                        Button("전체 날짜 보기") {
                            isDateFilterEnabled = false
                        }
                        .font(.caption.weight(.semibold))
                    }
                }
                calendarGrid
            }
            .careCard()
            .padding(.horizontal, 16)

            Text(statusText)
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
            if let errorMessage {
                ContentUnavailableView {
                    Label("기록을 불러오지 못했어요", systemImage: "exclamationmark.triangle")
                } description: {
                    Text(errorMessage)
                } actions: {
                    Button("다시 불러오기", action: loadRecords)
                }
            } else if records.isEmpty {
                EmptyStateView(icon: "list.bullet.clipboard", title: "아직 기록이 없어요", message: "식사, 산책, 증상 등을 기록하면 여기에 모아볼 수 있어요.", actionTitle: "기록 추가하기") {
                    showingAddRecord = true
                }
            } else if filteredRecords.isEmpty {
                EmptyStateView(icon: "calendar.badge.plus", title: isDateFilterEnabled ? "선택한 날짜의 기록이 없어요" : "해당 기록이 없어요", message: "기록추가 탭에서 기록을 남겨보세요")
            } else {
                ScrollView {
                    LazyVStack(spacing: 10) {
                        ForEach(filteredRecords) { record in
                            recordCard(record)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                }
            }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .navigationTitle("기록")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .navigationBar)
        .navigationDestination(isPresented: $showingAddRecord) { AddRecordView() }
        .onAppear {
            loadRecords()
        }
        .onReceive(NotificationCenter.default.publisher(for: .sampleDataDidChange)) { _ in
            selectedDate = Date()
            displayedMonth = Date()
            isDateFilterEnabled = false
            loadRecords()
        }
        .alert("이 기록을 삭제할까요?", isPresented: $showingDeleteConfirmation) {
            Button("취소", role: .cancel) {
                recordToDelete = nil
            }
            Button("삭제", role: .destructive) {
                deleteSelectedRecord()
            }
        } message: {
            Text("삭제한 기록은 되돌릴 수 없습니다.")
        }
    }

    private var statusText: String {
        if isDateFilterEnabled {
            return "선택한 날짜의 기록 \(filteredRecords.count)개"
        }
        return "전체 기록 \(filteredRecords.count)개"
    }

    private var monthTitle: String {
        displayedMonth.formatted(.dateTime.year().month(.wide))
    }

    private var calendarDays: [Date?] {
        let calendar = Calendar.current
        guard let monthInterval = calendar.dateInterval(of: .month, for: displayedMonth),
              let dayRange = calendar.range(of: .day, in: .month, for: displayedMonth) else { return [] }
        let firstWeekday = calendar.component(.weekday, from: monthInterval.start)
        let leadingEmptyDays = firstWeekday - calendar.firstWeekday
        let adjustedLeadingDays = (leadingEmptyDays + 7) % 7
        return Array(repeating: nil, count: adjustedLeadingDays)
            + dayRange.map { day in calendar.date(byAdding: .day, value: day - 1, to: monthInterval.start) }
    }

    private var calendarGrid: some View {
        VStack(spacing: 6) {
            HStack {
                ForEach(["일", "월", "화", "수", "목", "금", "토"], id: \.self) { weekday in
                    Text(weekday)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 2), count: 7), spacing: 4) {
                ForEach(Array(calendarDays.enumerated()), id: \.offset) { _, date in
                    if let date {
                        Button {
                            selectedDate = date
                            isDateFilterEnabled = true
                        } label: {
                            VStack(spacing: 2) {
                                Text(date, format: .dateTime.day())
                                    .font(.caption)
                                    .foregroundStyle(Calendar.current.isDate(date, inSameDayAs: selectedDate) && isDateFilterEnabled ? .white : .primary)
                                Circle()
                                    .fill(hasRecord(on: date) ? themeManager.theme.palette.accent : .clear)
                                    .frame(width: 4, height: 4)
                            }
                            .frame(maxWidth: .infinity, minHeight: 32)
                            .background(
                                Calendar.current.isDate(date, inSameDayAs: selectedDate) && isDateFilterEnabled
                                    ? themeManager.theme.palette.accent : .clear,
                                in: Circle()
                            )
                            .overlay(
                                Circle().stroke(
                                    Calendar.current.isDateInToday(date) ? themeManager.theme.palette.accent.opacity(0.55) : .clear,
                                    lineWidth: 1
                                )
                            )
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(date.formatted(.dateTime.month().day()))
                    } else {
                        Color.clear.frame(minHeight: 32)
                    }
                }
            }
        }
    }

    private func hasRecord(on date: Date) -> Bool {
        records.contains {
            let matchesPet = $0.petID == petStore.selectedPet?.id || ($0.petID == nil && petStore.isLegacyPetSelected)
            return matchesPet && Calendar.current.isDate($0.date, inSameDayAs: date)
        }
    }

    private func moveMonth(by value: Int) {
        if let month = Calendar.current.date(byAdding: .month, value: value, to: displayedMonth) {
            displayedMonth = month
        }
    }

    private func recordCard(_ record: CareRecord) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                if let data = record.imageData, let image = UIImage(data: data) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 72, height: 72)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                VStack(alignment: .leading, spacing: 4) {
                    Label(record.type, systemImage: recordSymbol(for: record.type))
                        .font(.subheadline.bold())
                        .foregroundStyle(themeManager.theme.palette.accent)
                        .padding(.horizontal, record.type == "몸무게" ? 8 : 0)
                        .padding(.vertical, record.type == "몸무게" ? 4 : 0)
                        .background(themeManager.theme.palette.accent.opacity(record.type == "몸무게" ? 0.12 : 0), in: Capsule())
                    Label {
                        Text(record.date, format: .dateTime.year().month().day().hour().minute())
                    } icon: {
                        Image(systemName: "calendar")
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
                Spacer()
                Button(role: .destructive) {
                    recordToDelete = record
                    showingDeleteConfirmation = true
                } label: {
                    Image(systemName: "trash")
                        .frame(minWidth: 44, minHeight: 44)
                }
                .buttonStyle(.borderless)
                .accessibilityLabel("\(record.title.isEmpty ? record.type : record.title) 기록 삭제")
            }

            Text(record.title.isEmpty ? "제목 없음" : record.title)
                .font(.headline)
                .foregroundStyle(textColor)
            Text(record.memo.isEmpty ? "메모 없음" : record.memo)
                .foregroundStyle(.secondary)
                .lineLimit(2)

            HStack(spacing: 6) {
                if let mealAmount = record.mealAmount {
                    detailTag("식사량: \(mealAmount)", systemImage: "fork.knife")
                }
                if let walkMinutes = record.walkMinutes {
                    detailTag("산책 \(walkMinutes)분", systemImage: "figure.walk")
                }
                if !record.symptoms.isEmpty {
                    detailTag("증상 \(record.symptoms.count)개", systemImage: "exclamationmark.triangle.fill")
                }
            }

        }
        .careCard()
    }

    private func detailTag(_ title: String, systemImage: String) -> some View {
        Label(title, systemImage: systemImage)
            .font(.caption2)
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(Color(.tertiarySystemGroupedBackground), in: Capsule())
            .foregroundStyle(.secondary)
    }

    private func loadRecords() {
        do {
            // 입력 시 선택한 기록 날짜와 시간을 기준으로 최신순 정렬합니다.
            records = try CareRecordStorage.load().sorted { $0.date > $1.date }
            errorMessage = nil
        } catch {
            errorMessage = "저장된 기록을 읽을 수 없습니다. 다시 시도해주세요."
        }
    }

    private func deleteSelectedRecord() {
        guard let record = recordToDelete else { return }
        recordToDelete = nil
        do {
            try CareRecordStorage.delete(id: record.id)
            loadRecords()
        } catch {
            errorMessage = "기록을 삭제하지 못했습니다. 다시 불러온 후 시도해주세요."
        }
    }
}
