import SwiftUI

enum TutorialAction: Equatable { case memoButtonTapped, careItemChecked, walkTimerOpened, weightOpened, profileOpened, historyTabOpened, supplementTabOpened, supplementChecked, petTipsTabOpened, petTipExpanded, managementOpened }

@MainActor
final class TutorialManager: ObservableObject {
    struct Step { let tab: Int; let title: String; let description: String; let requiredAction: TutorialAction? }
    @Published private(set) var isTutorialActive = false
    @Published private(set) var currentStep = 0
    @Published var showTutorialPrompt = false
    private let defaults: UserDefaults
    init(defaults: UserDefaults = .standard) { self.defaults = defaults }
    let steps: [Step] = [
        Step(tab: 0, title: "멍냥노트 둘러보기", description: "이제 주요 기능을 직접 눌러보며 익혀볼게요.", requiredAction: nil),
        Step(tab: 0, title: "오늘 한 줄 메모", description: "오늘 컨디션이나 특이사항은 이 버튼에서 남길 수 있어요. 버튼을 눌러보세요.", requiredAction: .memoButtonTapped),
        Step(tab: 0, title: "메모 카드 확인", description: "메모를 고정하면 홈에서 계속 볼 수 있어요. 내용을 확인한 뒤 다음을 눌러주세요.", requiredAction: nil),
        Step(tab: 0, title: "오늘의 케어", description: "매일 챙길 일을 체크해볼 수 있어요. 케어 항목을 눌러보세요.", requiredAction: .careItemChecked),
        Step(tab: 0, title: "산책 타이머", description: "산책 아이콘을 눌러 산책 시간을 기록할 수 있어요.", requiredAction: .walkTimerOpened),
        Step(tab: 0, title: "몸무게 기록", description: "몸무게 아이콘에서 몸무게와 변화를 기록할 수 있어요.", requiredAction: .weightOpened),
        Step(tab: 0, title: "프로필 확인", description: "프로필 사진을 누르면 아이의 기본 정보를 볼 수 있어요.", requiredAction: .profileOpened),
        Step(tab: 1, title: "기록", description: "기록 탭에서는 날짜별 기록과 사진 기록을 확인할 수 있어요.", requiredAction: .historyTabOpened),
        Step(tab: 2, title: "영양제", description: "영양제 탭에서는 급여량, 시간, 알림을 관리할 수 있어요.", requiredAction: .supplementTabOpened),
        Step(tab: 2, title: "영양제 체크", description: "오늘 먹인 영양제를 체크해보세요.", requiredAction: .supplementChecked),
        Step(tab: 3, title: "펫상식", description: "펫상식 탭에서는 강아지와 고양이 상식을 매일 볼 수 있어요.", requiredAction: .petTipsTabOpened),
        Step(tab: 3, title: "상식 펼쳐보기", description: "제목을 누르면 자세한 설명이 펼쳐져요.", requiredAction: .petTipExpanded),
        Step(tab: 0, title: "관리 메뉴", description: "관리 아이콘에서는 앱 사용법, 백업, 개인정보 안내를 볼 수 있어요.", requiredAction: .managementOpened),
        Step(tab: 0, title: "준비 완료!", description: "이제 멍냥노트로 우리 아이의 하루를 기록해보세요.", requiredAction: nil)
    ]
    var step: Step { steps[currentStep] }
    var isLastStep: Bool { currentStep == steps.count - 1 }
    var isWaitingForUserAction: Bool { step.requiredAction != nil }
    func startTutorial() { showTutorialPrompt = false; currentStep = 0; isTutorialActive = true }
    func nextStep() { guard isTutorialActive, !isLastStep else { return }; currentStep += 1 }
    func previousStep() { guard isTutorialActive, currentStep > 0 else { return }; currentStep -= 1 }
    func moveToStep(_ index: Int) {
        guard steps.indices.contains(index) else { return }
        currentStep = index
    }
    func skipTutorial() { finishTutorial() }
    func finishTutorial() { defaults.set(true, forKey: "hasSeenTutorial"); showTutorialPrompt = false; isTutorialActive = false }
    func advanceAfterAction(_ action: TutorialAction) { guard isTutorialActive, step.requiredAction == action else { return }; nextStep() }
}
