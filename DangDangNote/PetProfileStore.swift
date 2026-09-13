import Foundation
import SwiftUI

struct PetProfile: Identifiable, Codable, Equatable {
    var id = UUID()
    var name: String
    var species: String
    var breed: String
    var ageText: String
    var traits: [String]
    var imageData: Data?
}

final class PetProfileStore: ObservableObject {
    @Published var pets: [PetProfile] = []
    @Published var selectedPetID: UUID?

    var selectedPet: PetProfile? {
        pets.first { $0.id == selectedPetID } ?? pets.first
    }

    // 다중 반려동물 도입 전 저장된 petID 없는 데이터는 첫 번째 기본 프로필에게만 표시합니다.
    var isLegacyPetSelected: Bool {
        guard let selectedPetID, let firstPetID = pets.first?.id else { return true }
        return selectedPetID == firstPetID
    }

    private let petsKey = "petProfiles"
    private let selectedKey = "selectedPetProfileID"

    init() { loadPets() }

    func loadPets() {
        let defaults = UserDefaults.standard
        if let data = defaults.data(forKey: petsKey), let saved = try? JSONDecoder().decode([PetProfile].self, from: data), !saved.isEmpty {
            pets = saved
        } else {
            // 새 사용자는 개인 정보를 직접 입력하도록 빈 프로필로 시작합니다.
            // 기존 petProfiles 데이터가 있으면 위에서 그대로 보존합니다.
            pets = [PetProfile(name: "", species: "강아지", breed: "", ageText: "", traits: [], imageData: nil)]
            savePets()
        }
        if let idString = defaults.string(forKey: selectedKey), let id = UUID(uuidString: idString), pets.contains(where: { $0.id == id }) {
            selectedPetID = id
        } else {
            selectedPetID = pets.first?.id
            saveSelected()
        }
    }

    func savePets() {
        if let data = try? JSONEncoder().encode(pets) { UserDefaults.standard.set(data, forKey: petsKey) }
    }

    func addPet(_ pet: PetProfile) { pets.append(pet); savePets(); selectPet(pet) }
    func updatePet(_ pet: PetProfile) { if let index = pets.firstIndex(where: { $0.id == pet.id }) { pets[index] = pet; savePets() } }
    func deletePet(_ pet: PetProfile) {
        guard pets.count > 1 else { return }
        pets.removeAll { $0.id == pet.id }
        if selectedPetID == pet.id { selectedPetID = pets.first?.id; saveSelected() }
        savePets()
    }
    func selectPet(_ pet: PetProfile) { selectedPetID = pet.id; saveSelected() }

    private func saveSelected() { if let id = selectedPetID { UserDefaults.standard.set(id.uuidString, forKey: selectedKey) } }
}
