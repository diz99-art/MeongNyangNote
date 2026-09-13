import SwiftUI
import PhotosUI
import UIKit

struct CareRecord: Identifiable, Codable, Equatable {
    var id = UUID()
    var type: String
    var date: Date
    var title: String
    var memo: String
    var mealAmount: String?
    var walkMinutes: Int?
    var symptoms: [String]
    var imageData: Data? = nil
    var petID: UUID? = nil

    enum CodingKeys: String, CodingKey { case id, type, date, title, memo, mealAmount, walkMinutes, symptoms, imageData, petID }
    init(id: UUID = UUID(), type: String, date: Date, title: String, memo: String, mealAmount: String?, walkMinutes: Int?, symptoms: [String], imageData: Data? = nil, petID: UUID? = nil) {
        self.id = id; self.type = type; self.date = date; self.title = title; self.memo = memo
        self.mealAmount = mealAmount; self.walkMinutes = walkMinutes; self.symptoms = symptoms; self.imageData = imageData; self.petID = petID
    }
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        type = try c.decode(String.self, forKey: .type); date = try c.decode(Date.self, forKey: .date)
        title = try c.decode(String.self, forKey: .title); memo = try c.decode(String.self, forKey: .memo)
        mealAmount = try c.decodeIfPresent(String.self, forKey: .mealAmount); walkMinutes = try c.decodeIfPresent(Int.self, forKey: .walkMinutes)
        symptoms = try c.decodeIfPresent([String].self, forKey: .symptoms) ?? []
        imageData = try c.decodeIfPresent(Data.self, forKey: .imageData)
        petID = try c.decodeIfPresent(UUID.self, forKey: .petID)
    }
}

struct AddRecordView: View {
    @EnvironmentObject private var themeManager: ThemeManager
    @EnvironmentObject private var petStore: PetProfileStore
    @State private var categories = RecordTypeStorage.load()
    @State private var showingTypeManager = false
    private let mealAmountLabels = ["잘 먹음", "조금", "안 먹음"]
    private let symptomOptions = [
        "구토", "설사", "식욕 저하", "눈물 증가", "피부 가려움", "절뚝거림", "새벽에 자주 깸"
    ]

    @State private var category = "식사"
    @State private var date = Date.now
    @State private var title = ""
    @State private var memo = ""
    @State private var mealAmount = "잘 먹음"
    @State private var walkMinutes = 20
    @State private var selectedSymptoms: Set<String> = []
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var showingPhotoError = false
    @State private var recordImageData: Data?
    @AppStorage("selectedTextColor") private var selectedTextColor = AppTextColor.black.rawValue
    @FocusState private var isEditingText: Bool

    private var textColor: Color { themeManager.theme.palette.text }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Label("오늘 우리 강아지에게 있었던 일을 남겨보세요", systemImage: "pawprint.fill")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 4)

                inputCard("기록 유형") {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(categories, id: \.self) { type in
                                Button {
                                    category = type
                                } label: {
                                    Label(type, systemImage: recordSymbol(for: type))
                                        .font(.subheadline.weight(.semibold))
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 12)
                                        .background(category == type ? themeManager.theme.palette.accent.opacity(0.20) : Color(.tertiarySystemGroupedBackground), in: Capsule())
                                        .overlay(Capsule().stroke(category == type ? themeManager.theme.palette.accent : .clear, lineWidth: 2))
                                }
                                .buttonStyle(.plain)
                                .accessibilityAddTraits(category == type ? .isSelected : [])
                            }
                        }
                        .padding(2)
                    }
                    Button {
                        showingTypeManager = true
                    } label: {
                        Label("기록 유형 관리", systemImage: "slider.horizontal.3")
                            .font(.caption.weight(.semibold))
                    }
                    .buttonStyle(.borderless)
                }

                inputCard("기본 정보") {
                    DatePicker("날짜와 시간", selection: $date)
                    Divider()
                    TextField("제목을 입력하세요", text: $title)
                        .textFieldStyle(.roundedBorder)
                        .focused($isEditingText)
                }

                if category == "식사" {
                    inputCard("식사") {
                        HStack(spacing: 8) {
                            Text("식사량")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            ForEach(mealAmountLabels, id: \.self) { label in
                                Button {
                                    mealAmount = mealAmountValue(for: label)
                                } label: {
                                    Text(label)
                                        .font(.caption.weight(.semibold))
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 7)
                                        .background(
                                            mealAmount == mealAmountValue(for: label)
                                                ? themeManager.theme.palette.accent.opacity(0.20)
                                                : Color(.tertiarySystemGroupedBackground),
                                            in: Capsule()
                                        )
                                        .overlay(
                                            Capsule().stroke(
                                                mealAmount == mealAmountValue(for: label)
                                                    ? themeManager.theme.palette.accent : .clear,
                                                lineWidth: 1
                                            )
                                        )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                } else if category == "산책" {
                    inputCard("산책 시간을 입력해주세요") {
                        Stepper("산책 시간: \(walkMinutes)분", value: $walkMinutes, in: 0...180, step: 5)
                    }
                } else if category == "증상" {
                    inputCard("증상을 선택해주세요") {
                        ForEach(symptomOptions, id: \.self) { symptom in
                            Button {
                                if selectedSymptoms.contains(symptom) {
                                    selectedSymptoms.remove(symptom)
                                } else {
                                    selectedSymptoms.insert(symptom)
                                }
                            } label: {
                                HStack {
                                    Text(symptom)
                                        .foregroundStyle(.primary)
                                    Spacer()
                                    Image(systemName: selectedSymptoms.contains(symptom)
                                          ? "checkmark.circle.fill" : "circle")
                                }
                                .frame(minHeight: 44)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.borderless)
                            .accessibilityValue(selectedSymptoms.contains(symptom) ? "선택됨" : "선택 안 됨")
                        }
                    }
                }

                inputCard("상세 메모") {
                    ZStack(alignment: .topLeading) {
                        TextEditor(text: $memo)
                            .frame(minHeight: 160)
                            .scrollContentBackground(.hidden)
                            .focused($isEditingText)
                            .accessibilityLabel("메모")
                        if memo.isEmpty {
                            Text("메모를 입력하세요")
                                .foregroundStyle(.secondary)
                                .padding(.top, 8)
                                .padding(.leading, 5)
                                .allowsHitTesting(false)
                                .accessibilityHidden(true)
                        }
                    }
                }

                inputCard("사진 기록 (선택)") {
                    if let data = recordImageData, let image = UIImage(data: data) {
                        Image(uiImage: image).resizable().scaledToFill().frame(height: 160).clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    PhotosPicker(selection: $selectedPhoto, matching: .images) {
                        Label(recordImageData == nil ? "사진 선택" : "사진 다시 선택", systemImage: "photo")
                    }
                    .buttonStyle(.bordered)
                    Text("선택한 사진만 기기에 저장돼요.")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                Button(action: saveRecord) {
                    Text("기록 저장")
                        .font(.headline)
                        .frame(maxWidth: .infinity, minHeight: 44)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
            .padding(16)
        }
        .background(CareBackground())
        .tint(themeManager.theme.palette.accent)
        .navigationTitle("기록 추가")
        .navigationBarTitleDisplayMode(.inline)
        .scrollDismissesKeyboard(.interactively)
        .task(id: selectedPhoto) {
            guard let photo = selectedPhoto else { return }
            guard let data = try? await photo.loadTransferable(type: Data.self), let image = UIImage(data: data) else {
                showingPhotoError = true
                return
            }
            recordImageData = compressedImageData(from: image)
            selectedPhoto = nil
        }
        .alert("사진을 불러오지 못했어요", isPresented: $showingPhotoError) {
            Button("확인", role: .cancel) { selectedPhoto = nil }
        } message: {
            Text("다른 사진을 선택해 보거나 사진 접근 권한을 확인해 주세요.")
        }
        .alert(alertMessage, isPresented: $showingAlert) {
            Button("확인", role: .cancel) { }
        }
        .sheet(isPresented: $showingTypeManager) {
            RecordTypeManagerView(categories: $categories, selectedCategory: $category)
                .environmentObject(themeManager)
        }
        .onChange(of: categories) { _, newCategories in
            RecordTypeStorage.save(newCategories)
            if newCategories.isEmpty {
                categories = RecordTypeStorage.defaults
            }
            if !categories.contains(category) {
                category = categories.first ?? "식사"
            }
        }
    }

    // 카드의 공통 여백과 배경만 한 곳에서 관리합니다.
    private func inputCard<Content: View>(
        _ heading: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(heading)
                .font(.headline)
                .foregroundStyle(textColor)
            content()
        }
        .careCard()
    }

    private func saveRecord() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else {
            alertMessage = "제목을 입력해주세요"
            showingAlert = true
            return
        }

        let record = CareRecord(
            type: category,
            date: date,
            title: trimmedTitle,
            memo: memo,
            // 선택한 유형에 해당하는 상세 정보만 저장합니다.
            mealAmount: category == "식사" ? mealAmount : nil,
            walkMinutes: category == "산책" ? walkMinutes : nil,
            symptoms: category == "증상" ? symptomOptions.filter { selectedSymptoms.contains($0) } : [],
            imageData: recordImageData
            , petID: petStore.selectedPet?.id
        )

        do {
            try CareRecordStorage.append(record)
            category = "식사"
            date = .now
            title = ""
            memo = ""
            mealAmount = "잘 먹음"
            walkMinutes = 20
            selectedSymptoms = []
            selectedPhoto = nil
            recordImageData = nil
            isEditingText = false
            alertMessage = "기록이 저장되었습니다."
        } catch {
            // 저장에 실패하면 입력값과 기존 기록을 유지합니다.
            alertMessage = "기록을 저장하지 못했습니다. 다시 시도해주세요."
        }
        showingAlert = true
    }

    private func compressedImageData(from image: UIImage) -> Data? {
        let longestSide = max(image.size.width, image.size.height)
        guard longestSide > 0 else { return nil }
        let scale = min(900 / longestSide, 1)
        let size = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: size)
        let resized = renderer.image { _ in image.draw(in: CGRect(origin: .zero, size: size)) }
        return resized.jpegData(compressionQuality: 0.7)
    }

    private func mealAmountValue(for label: String) -> String {
        label == "조금" ? "조금 먹음" : label
    }
}

// 기존 기록을 불러온 뒤 새 기록을 추가하고 JSON Data로 저장합니다.
enum CareRecordStorage {
    private static let key = "careRecords"

    static func load(from defaults: UserDefaults = .standard) throws -> [CareRecord] {
        guard let data = defaults.data(forKey: key) else { return [] }
        return try JSONDecoder().decode([CareRecord].self, from: data)
    }

    static func append(_ record: CareRecord, to defaults: UserDefaults = .standard) throws {
        var records = try load(from: defaults)
        records.append(record)
        let data = try JSONEncoder().encode(records)
        defaults.set(data, forKey: key)
    }

    static func delete(id: UUID, from defaults: UserDefaults = .standard) throws {
        // 최신 목록에서 해당 ID만 삭제해 다른 기록을 유지합니다.
        var records = try load(from: defaults)
        records.removeAll { $0.id == id }
        let data = try JSONEncoder().encode(records)
        defaults.set(data, forKey: key)
    }
}

enum RecordTypeStorage {
    static let key = "recordTypes"
    static let defaults = ["식사", "산책", "증상", "병원", "기타"]

    static func load(from defaultsStore: UserDefaults = .standard) -> [String] {
        let saved = defaultsStore.stringArray(forKey: key) ?? []
        return saved.isEmpty ? defaults : saved
    }

    static func save(_ types: [String], to defaultsStore: UserDefaults = .standard) {
        defaultsStore.set(types, forKey: key)
    }
}

private struct RecordTypeManagerView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var themeManager: ThemeManager
    @Binding var categories: [String]
    @Binding var selectedCategory: String
    @State private var newType = ""

    private var trimmedType: String { newType.trimmingCharacters(in: .whitespacesAndNewlines) }

    var body: some View {
        NavigationStack {
            List {
                Section("기록 유형") {
                    ForEach(categories, id: \.self) { type in
                        HStack {
                            Text(type)
                            Spacer()
                            Button(role: .destructive) {
                                categories.removeAll { $0 == type }
                                RecordTypeStorage.save(categories)
                            } label: {
                                Image(systemName: "trash")
                            }
                            .buttonStyle(.borderless)
                        }
                    }
                }
                Section {
                    HStack {
                        TextField("새 유형 이름", text: $newType)
                        Button("추가") { addType() }
                            .disabled(trimmedType.isEmpty || categories.contains(trimmedType))
                    }
                }
            }
            .navigationTitle("기록 유형 관리")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("닫기") { dismiss() }
                }
            }
        }
        .tint(themeManager.theme.palette.accent)
        .presentationDetents([.medium])
    }

    private func addType() {
        guard !trimmedType.isEmpty, !categories.contains(trimmedType) else { return }
        categories.append(trimmedType)
        RecordTypeStorage.save(categories)
        newType = ""
    }
}
