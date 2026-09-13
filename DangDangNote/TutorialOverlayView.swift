import SwiftUI

struct TutorialOverlayView: View {
    @EnvironmentObject private var tutorialManager: TutorialManager
    @EnvironmentObject private var themeManager: ThemeManager
    @AccessibilityFocusState private var isTitleFocused: Bool

    private var palette: ThemePalette { themeManager.theme.palette }

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottom) {
                Color.black.opacity(0.16)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)

                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        HStack {
                            Text("\(tutorialManager.currentStep + 1) / \(tutorialManager.steps.count)")
                                .font(.caption.bold())
                            Spacer()
                            Button("건너뛰기") { tutorialManager.skipTutorial() }
                                .font(.subheadline)
                                .frame(minHeight: 44)
                        }
                        Text(tutorialManager.step.title)
                            .font(.title3.bold())
                            .accessibilityAddTraits(.isHeader)
                            .accessibilityFocused($isTitleFocused)
                        Text(tutorialManager.step.description)
                            .font(.subheadline)
                            .fixedSize(horizontal: false, vertical: true)
                        if tutorialManager.isLastStep {
                            Divider()
                            Text("준비 완료!").font(.headline)
                            Text("이제 멍냥노트로 우리 아이의 하루를 기록해보세요.")
                                .font(.subheadline)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        HStack(spacing: 12) {
                            if tutorialManager.currentStep > 0 {
                                Button("이전") { tutorialManager.previousStep() }
                                    .frame(minWidth: 60, minHeight: 48)
                                    .background(palette.accent.opacity(0.08), in: Capsule())
                            }
                            if !tutorialManager.isWaitingForUserAction {
                            Button {
                                if tutorialManager.isLastStep { tutorialManager.finishTutorial() }
                                else { tutorialManager.nextStep() }
                            } label: {
                                Text(tutorialManager.isLastStep ? "시작하기" : "다음")
                                    .frame(maxWidth: .infinity, minHeight: 48)
                            }
                            .background(palette.accent.opacity(0.22), in: Capsule())
                            } else {
                                Text("표시된 기능을 눌러보세요")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(palette.accent)
                                    .frame(maxWidth: .infinity, minHeight: 48)
                                    .background(palette.accent.opacity(0.08), in: Capsule())
                            }
                        }
                        .font(.headline)
                    }
                    .padding(18)
                }
                .scrollBounceBehavior(.basedOnSize)
                .frame(maxHeight: min(geometry.size.height * 0.62, 420))
                .background(palette.card, in: RoundedRectangle(cornerRadius: 24))
                .overlay(RoundedRectangle(cornerRadius: 24).stroke(palette.accent.opacity(0.20)))
                .padding(16)
                .padding(.bottom, 48)
                .foregroundStyle(palette.text)
                .buttonStyle(.plain)
                .accessibilityAddTraits(.isModal)
            }
        }
        .onAppear { isTitleFocused = true }
        .onChange(of: tutorialManager.currentStep) { _, _ in isTitleFocused = true }
    }
}
