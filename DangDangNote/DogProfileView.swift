import SwiftUI
import PhotosUI
import UIKit

struct DogProfileView: View {
    @EnvironmentObject private var themeManager: ThemeManager
    @EnvironmentObject private var petStore: PetProfileStore
    @AppStorage("dogProfileImageData") private var imageData: Data?
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var showingPhotoError = false
    @State private var showingTraitEditor = false
    private var textColor: Color { themeManager.theme.palette.text }
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                VStack(spacing: 12) {
                    PhotosPicker(selection: $selectedPhoto, matching: .images) {
                        DogProfileImage(size: 132)
                            .overlay(Circle().stroke(themeManager.theme.palette.accent.opacity(0.25), lineWidth: 4))
                            .overlay(alignment: .bottomTrailing) {
                                Image(systemName: "camera.fill")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(themeManager.theme.palette.text)
                                    .padding(8)
                                    .background(themeManager.theme.palette.card, in: Circle())
                                    .overlay(Circle().stroke(themeManager.theme.palette.accent.opacity(0.25), lineWidth: 1))
                            }
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("프로필 사진 변경")
                    Text(profileName).font(.title.bold()).foregroundStyle(textColor)
                    if let pet = petStore.selectedPet {
                        let details = [pet.breed.isEmpty ? "품종 미입력" : pet.breed,
                                       pet.ageText.isEmpty ? "나이 미입력" : pet.ageText].joined(separator: " · ")
                        Text(details)
                            .font(.subheadline)
                            .foregroundStyle(textColor.opacity(0.7))
                    }
                    if petStore.selectedPet?.imageData != nil || imageData != nil {
                        Button(role: .destructive) {
                            selectedPhoto = nil
                            imageData = nil
                            if var pet = petStore.selectedPet {
                                pet.imageData = nil
                                petStore.updatePet(pet)
                            }
                        } label: {
                            Label("사진 삭제", systemImage: "trash")
                                .font(.caption)
                        }
                        .buttonStyle(.borderless)
                    }
                    Text("사진을 눌러 변경")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text("선택한 사진만 기기에 저장돼요.")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .careCard()

                VStack(alignment: .leading, spacing: 14) {
                    Label("기본 정보", systemImage: "pawprint.fill").font(.headline).foregroundStyle(textColor)
                    LabeledContent("이름", value: profileName).foregroundStyle(textColor)
                    Divider()
                    LabeledContent("종류", value: petStore.selectedPet?.species.isEmpty == false ? petStore.selectedPet!.species : "종류 미입력")
                    Divider()
                    LabeledContent("품종", value: petStore.selectedPet?.breed.isEmpty == false ? petStore.selectedPet!.breed : "품종 미입력").foregroundStyle(textColor)
                    Divider()
                    LabeledContent("나이", value: petStore.selectedPet?.ageText.isEmpty == false ? petStore.selectedPet!.ageText : "나이 미입력").foregroundStyle(textColor)
                }
                .careCard()


                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        Label("특이사항", systemImage: "heart.text.clipboard").font(.headline).foregroundStyle(textColor)
                        Spacer()
                        Button("수정") { showingTraitEditor = true }
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(themeManager.theme.palette.accent)
                    }
                    let traits = petStore.selectedPet?.traits ?? []
                    if traits.isEmpty {
                        Text("등록된 특이사항이 없어요").font(.subheadline).foregroundStyle(.secondary)
                    } else {
                        ForEach(Array(traits.enumerated()), id: \.offset) { _, trait in
                            Text(trait).font(.subheadline).foregroundStyle(textColor)
                        }
                    }
                }
                .careCard()


            }
            .padding(16)
        }
        .background(CareBackground())
        .navigationTitle("반려동물 프로필")
        .toolbar(.visible, for: .navigationBar)
        .navigationBarTitleDisplayMode(.inline)
        .tint(themeManager.theme.palette.accent)
        .sheet(isPresented: $showingTraitEditor) {
            if let pet = petStore.selectedPet {
                TraitEditView(traits: pet.traits) { updatedTraits in
                    var updatedPet = pet
                    updatedPet.traits = updatedTraits
                    petStore.updatePet(updatedPet)
                }
                .environmentObject(themeManager)
            }
        }
        .task(id: selectedPhoto) {
            guard let photo = selectedPhoto else { return }
            do {
                guard let data = try await photo.loadTransferable(type: Data.self),
                      let image = UIImage(data: data),
                      let savedData = profileImageData(from: image) else {
                    if !Task.isCancelled { showingPhotoError = true }
                    return
                }
                // 사진을 다시 선택하거나 삭제했다면 이전 로딩 결과는 사용하지 않습니다.
                guard !Task.isCancelled else { return }
                imageData = savedData
                if var pet = petStore.selectedPet { pet.imageData = savedData; petStore.updatePet(pet) }
                selectedPhoto = nil
            } catch {
                if !Task.isCancelled { showingPhotoError = true }
            }
        }
        .alert("사진을 불러오지 못했어요", isPresented: $showingPhotoError) {
            Button("확인") { selectedPhoto = nil }
        } message: {
            Text("다른 사진을 선택해 보거나 사진 접근 권한을 확인해 주세요.")
        }
    }

    private func profileImageData(from image: UIImage) -> Data? {
        // UserDefaults에는 원본 대신 최대 512픽셀 크기의 JPEG를 저장합니다.
        let longestSide = max(image.size.width, image.size.height)
        guard longestSide > 0 else { return nil }
        let scale = min(512 / longestSide, 1)
        let size = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let resizedImage = UIGraphicsImageRenderer(size: size, format: format).image { _ in
            image.draw(in: CGRect(origin: .zero, size: size))
        }
        return resizedImage.jpegData(compressionQuality: 0.8)
    }

    private var profileName: String {
        let name = petStore.selectedPet?.name.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return name.isEmpty ? "이름을 입력해주세요" : name
    }

}

private struct TraitEditView: View {
    @EnvironmentObject private var themeManager: ThemeManager
    @Environment(\.dismiss) private var dismiss
    @State private var traits: [String]
    @State private var newTrait = ""
    let onSave: ([String]) -> Void

    init(traits: [String], onSave: @escaping ([String]) -> Void) {
        _traits = State(initialValue: traits)
        self.onSave = onSave
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("새 특이사항") {
                    HStack {
                        TextField("예: 알레르기, 식습관", text: $newTrait)
                        Button("추가") { addTrait() }
                            .disabled(newTrait.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }
                Section("등록된 특이사항") {
                    if traits.isEmpty {
                        Text("등록된 특이사항이 없어요").foregroundStyle(.secondary)
                    } else {
                        ForEach(Array(traits.enumerated()), id: \.offset) { index, _ in
                            HStack {
                                TextField("특이사항", text: Binding(
                                    get: { traits[index] },
                                    set: { traits[index] = $0 }
                                ))
                                Button(role: .destructive) { traits.remove(at: index) } label: {
                                    Image(systemName: "trash")
                                }
                                .accessibilityLabel("특이사항 삭제")
                            }
                        }
                        .onDelete { traits.remove(atOffsets: $0) }
                    }
                }
            }
            .navigationTitle("특이사항 수정")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("닫기") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("저장") { save() } }
            }
        }
        .tint(themeManager.theme.palette.accent)
        .presentationDetents([.medium, .large])
    }

    private func addTrait() {
        let value = newTrait.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty, !traits.contains(value) else { return }
        traits.append(value)
        newTrait = ""
    }

    private func save() {
        let cleaned = traits.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .reduce(into: [String]()) { result, value in
                if !result.contains(value) { result.append(value) }
            }
        onSave(cleaned)
        dismiss()
    }
}

// 두 화면에서 같은 저장 키를 읽으므로 사진 선택과 삭제가 함께 반영됩니다.
struct DogProfileImage: View {
    @EnvironmentObject private var themeManager: ThemeManager
    @EnvironmentObject private var petStore: PetProfileStore
    let size: CGFloat

    var body: some View {
        Group {
            if let data = displayImageData, let image = UIImage(data: data) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                ZStack {
                    Circle().fill(themeManager.theme.palette.accent.opacity(0.12))
                    Image(systemName: "pawprint.fill")
                        .font(.system(size: size * 0.45))
                        .foregroundStyle(themeManager.theme.palette.accent)
                }
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .accessibilityLabel("\(petStore.selectedPet?.name ?? "반려동물") 프로필 사진")
    }

    private var displayImageData: Data? {
        // 새 기본 프로필에는 legacy dogProfileImageData를 자동 이관하지 않습니다.
        return petStore.selectedPet?.imageData
    }
}
