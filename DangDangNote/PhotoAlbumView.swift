import SwiftUI
import UIKit

struct PhotoAlbumView: View {
    @EnvironmentObject private var themeManager: ThemeManager
    @EnvironmentObject private var petStore: PetProfileStore
    @State private var records: [CareRecord] = []
    @State private var selectedRecord: CareRecord?
    @State private var loadFailed = false

    private var photoRecords: [CareRecord] {
        records.filter { record in
            guard let data = record.imageData else { return false }
            return UIImage(data: data) != nil && (record.petID == petStore.selectedPet?.id || (record.petID == nil && petStore.isLegacyPetSelected))
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("사진 앨범").font(.largeTitle.bold())
                    Text("기록에 남긴 사진을 모아봤어요").font(.subheadline).foregroundStyle(.secondary)
                }

                if loadFailed {
                    Text("사진 기록을 불러오지 못했어요").foregroundStyle(.secondary).careCard()
                } else if photoRecords.isEmpty {
                    EmptyStateView(icon: "photo.on.rectangle.angled", title: "아직 사진 기록이 없어요", message: "기록추가에서 사진을 남기면 여기에서 모아볼 수 있어요")
                } else {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                        ForEach(photoRecords) { record in
                            Button { selectedRecord = record } label: {
                                VStack(alignment: .leading, spacing: 6) {
                                    if let data = record.imageData, let image = UIImage(data: data) {
                                        Image(uiImage: image)
                                            .resizable().scaledToFill()
                                            .frame(height: 150)
                                            .frame(maxWidth: .infinity)
                                            .clipShape(RoundedRectangle(cornerRadius: 14))
                                    }
                                    Text(record.title.isEmpty ? "제목 없음" : record.title)
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(themeManager.theme.palette.text)
                                        .lineLimit(1)
                                    Text(record.date, format: .dateTime.year().month().day())
                                        .font(.caption).foregroundStyle(.secondary)
                                }
                                .padding(8)
                                .background(themeManager.theme.palette.card, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .padding(16)
        }
        .background(CareBackground())
        .navigationTitle("사진 앨범")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear(perform: loadRecords)
        .onReceive(NotificationCenter.default.publisher(for: .sampleDataDidChange)) { _ in
            selectedRecord = nil
            loadRecords()
        }
        .sheet(item: $selectedRecord) { record in
            PhotoDetailView(record: record)
                .environmentObject(themeManager)
        }
    }

    private func loadRecords() {
        do {
            records = try CareRecordStorage.load().sorted { $0.date > $1.date }
            loadFailed = false
        } catch {
            loadFailed = true
        }
    }
}

private struct PhotoDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var themeManager: ThemeManager
    let record: CareRecord

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    if let data = record.imageData, let image = UIImage(data: data) {
                        Image(uiImage: image)
                            .resizable().scaledToFit()
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    }
                    Text(record.title.isEmpty ? "제목 없음" : record.title).font(.title3.bold())
                    Label(record.type, systemImage: recordSymbol(for: record.type))
                        .foregroundStyle(themeManager.theme.palette.accent)
                    Text(record.date, format: .dateTime.year().month().day().hour().minute())
                        .font(.subheadline).foregroundStyle(.secondary)
                    if !record.memo.isEmpty {
                        Text(record.memo).font(.body).foregroundStyle(.secondary)
                    }
                }
                .padding(20)
            }
            .background(CareBackground())
            .navigationTitle("사진 보기")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("닫기") { dismiss() } } }
        }
        .presentationDetents([.medium, .large])
    }
}
