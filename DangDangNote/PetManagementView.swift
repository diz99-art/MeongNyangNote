import SwiftUI
import PhotosUI

struct PetManagementView: View {
    @EnvironmentObject private var themeManager: ThemeManager
    @EnvironmentObject private var petStore: PetProfileStore
    @Environment(\.dismiss) private var dismiss
    @State private var showingPetEditor = false
    @State private var editingPet: PetProfile?
    @State private var petToDelete: PetProfile?
    @State private var showingPetDeleteAlert = false


    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("아이를 추가하고 선택할 수 있어요")
                    .font(.subheadline)
                ForEach(petStore.pets) { pet in
                    HStack(spacing: 10) {
                        Button { petStore.selectPet(pet) } label: {
                            HStack(spacing: 10) {
                                Group {
                                    if let data = pet.imageData, let image = UIImage(data: data) {
                                        Image(uiImage: image).resizable().scaledToFill()
                                    } else {
                                        Image(systemName: pet.species == "고양이" ? "cat.fill" : "pawprint.fill")
                                            .foregroundStyle(themeManager.theme.palette.accent)
                                    }
                                }
                                .frame(width: 44, height: 44)
                                .clipShape(Circle())
                                .accessibilityLabel("\(pet.name) 프로필 사진")
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(pet.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "이름 입력" : pet.name)
                                        .font(.headline)
                                    Text(petDetails(for: pet)).font(.caption)
                                }
                                Spacer(minLength: 0)
                                if pet.id == petStore.selectedPetID {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(themeManager.theme.palette.accent)
                                }
                            }
                            .frame(minHeight: 44)
                            .contentShape(Rectangle())
                        }
                        .accessibilityValue(pet.id == petStore.selectedPetID ? "선택됨" : "선택 안 됨")
                        Button { editingPet = pet; showingPetEditor = true } label: {
                            Image(systemName: "pencil").frame(width: 44, height: 44)
                        }
                        .accessibilityLabel("\(pet.name) 수정")
                        Button(role: .destructive) { petToDelete = pet; showingPetDeleteAlert = true } label: {
                            Image(systemName: "trash").frame(width: 44, height: 44)
                        }
                        .disabled(petStore.pets.count == 1)
                        .accessibilityLabel("\(pet.name) 삭제")
                    }
                    .buttonStyle(.plain)
                    .careCard()
                }
                Button { editingPet = nil; showingPetEditor = true } label: {
                    Label("반려동물 추가", systemImage: "plus.circle.fill")
                }
                .buttonStyle(.bordered)
                NavigationLink {
                    ManagementView()
                } label: {
                    Label("앱 설정 및 모아보기", systemImage: "slider.horizontal.3")
                        .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                        .careCard()
                }
                .buttonStyle(.plain)
            }
            .foregroundStyle(themeManager.theme.palette.text)
            .padding(16)
        }
        .background(CareBackground())
        .navigationTitle("반려동물 관리")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { ToolbarItem(placement: .cancellationAction) { Button("닫기") { dismiss() } } }
        .sheet(isPresented: $showingPetEditor) {
            PetEditorView(pet: editingPet) { pet in
                if editingPet == nil { petStore.addPet(pet) } else { petStore.updatePet(pet) }
                showingPetEditor = false
            }
            .environmentObject(themeManager)
        }
        .alert("이 반려동물을 삭제할까요?", isPresented: $showingPetDeleteAlert) {
            Button("취소", role: .cancel) { petToDelete = nil }
            Button("삭제", role: .destructive) {
                if let petToDelete { petStore.deletePet(petToDelete) }
                petToDelete = nil
            }
        }
    }

    private func petDetails(for pet: PetProfile) -> String {
        let species = pet.species.isEmpty ? "종류 미입력" : pet.species
        let breed = pet.breed.isEmpty ? "품종 미입력" : pet.breed
        let age = pet.ageText.isEmpty ? "나이 미입력" : pet.ageText
        return [species, breed, age].joined(separator: " · ")
    }

}

private struct PetEditorView: View {
    @Environment(\.dismiss) private var dismiss
    let pet: PetProfile?
    let onSave: (PetProfile) -> Void
    @State private var name: String
    @State private var species: String
    @State private var breed: String
    @State private var ageText: String
    @State private var traitsText: String
    @State private var imageData: Data?
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var showingPhotoError = false

    init(pet: PetProfile?, onSave: @escaping (PetProfile) -> Void) {
        self.pet = pet; self.onSave = onSave
        _name = State(initialValue: pet?.name ?? ""); _species = State(initialValue: pet?.species ?? "강아지")
        _breed = State(initialValue: pet?.breed ?? ""); _ageText = State(initialValue: pet?.ageText ?? "")
        _traitsText = State(initialValue: pet?.traits.joined(separator: ", ") ?? ""); _imageData = State(initialValue: pet?.imageData)
    }

    var body: some View {
        NavigationStack {
            Form {
                TextField("이름", text: $name)
                Picker("종류", selection: $species) { Text("강아지").tag("강아지"); Text("고양이").tag("고양이"); Text("기타").tag("기타") }
                TextField("품종", text: $breed); TextField("나이", text: $ageText); TextField("특징 (쉼표로 구분)", text: $traitsText)
                PhotosPicker(selection: $selectedPhoto, matching: .images) { Label("사진 선택", systemImage: "photo") }
                Text("선택한 사진만 기기에 저장돼요.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Button("저장") {
                    let traits = traitsText.split(separator: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
                    onSave(PetProfile(id: pet?.id ?? UUID(), name: name, species: species, breed: breed, ageText: ageText, traits: traits, imageData: imageData))
                }.disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .navigationTitle(pet == nil ? "반려동물 추가" : "반려동물 수정")
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("취소") { dismiss() } } }
        }
        .task(id: selectedPhoto) {
            guard let photo = selectedPhoto, let data = try? await photo.loadTransferable(type: Data.self) else {
                if selectedPhoto != nil { showingPhotoError = true }
                return
            }
            imageData = data; selectedPhoto = nil
        }
        .alert("사진을 불러오지 못했어요", isPresented: $showingPhotoError) {
            Button("확인", role: .cancel) { selectedPhoto = nil }
        } message: {
            Text("다른 사진을 선택해 보거나 사진 접근 권한을 확인해 주세요.")
        }
        .presentationDetents([.medium, .large])
    }
}
