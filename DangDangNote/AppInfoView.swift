import SwiftUI

struct AppInfoView: View {
    @EnvironmentObject private var themeManager: ThemeManager

    private var palette: ThemePalette { themeManager.theme.palette }
    private var version: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }
    private var build: String? {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String
    }

    private let features = [
        "반려동물 여러 마리 관리", "오늘의 케어 체크", "식사·산책·증상·병원 기록",
        "사진 기록과 사진 앨범", "영양제 관리와 알림", "몸무게 기록과 그래프",
        "월간 리포트", "강아지/고양이 펫상식", "데이터 백업/복원"
    ]
    private let storeFeatures = [
        "오늘의 케어 체크리스트", "식사·산책·증상·병원 기록", "사진 첨부와 사진 앨범",
        "영양제 관리 및 알림", "몸무게 기록과 변화 확인", "월간 케어 리포트",
        "강아지/고양이 기본상식", "여러 마리 반려동물 관리", "데이터 백업/복원"
    ]
    private let storeDescription = """
    멍냥노트는 우리 아이의 하루를 쉽고 따뜻하게 기록하는 반려동물 케어 노트입니다.

    식사, 산책, 증상, 병원 방문 기록부터 영양제 체크, 사진 앨범, 몸무게 변화, 월간 리포트까지 한곳에서 관리할 수 있어요.

    강아지와 고양이를 함께 관리할 수 있고, 여러 마리 반려동물도 등록할 수 있습니다. 매일 제공되는 펫상식으로 반려생활에 필요한 기본 정보도 확인해 보세요.
    """

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 12) {
                    Image(systemName: "pawprint.fill")
                        .font(.largeTitle)
                        .foregroundStyle(palette.accent)
                        .padding(12)
                        .background(palette.accent.opacity(0.12), in: RoundedRectangle(cornerRadius: 18))
                    Text("멍냥노트")
                        .font(.title2.bold())
                        .accessibilityAddTraits(.isHeader)
                    Text("멍냥노트는 반려동물의 하루 케어, 기록, 영양제, 사진, 월간 리포트를 한곳에서 관리할 수 있는 반려동물 케어 노트입니다.")
                        .font(.subheadline)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .careCard()

                VStack(alignment: .leading, spacing: 12) {
                    heading("주요 기능", icon: "checkmark.seal.fill")
                    featureList(features)
                }
                .careCard()

                VStack(spacing: 12) {
                    LabeledContent("앱 버전", value: version)
                    if let build, !build.isEmpty {
                        Divider()
                        LabeledContent("빌드 번호", value: build)
                    }
                }
                .font(.subheadline)
                .careCard()

                NavigationLink {
                    PrivacyInfoView()
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "lock.shield.fill")
                            .font(.title2)
                            .foregroundStyle(palette.accent)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("개인정보 안내").font(.headline)
                            Text("기록과 사진이 저장되는 방식을 확인해요")
                                .font(.caption)
                                .foregroundStyle(palette.secondaryText)
                        }
                        Spacer(minLength: 8)
                        Image(systemName: "chevron.right")
                            .font(.caption.weight(.semibold))
                    }
                    .fixedSize(horizontal: false, vertical: true)
                    .careCard()
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                VStack(alignment: .leading, spacing: 12) {
                    heading("앱 소개문", icon: "text.bubble.fill")
                    Text("앱스토어 소개문 초안")
                        .font(.subheadline.bold())
                    Text("앱 안에서 참고하는 초안이에요. 실제 App Store 등록 문구는 추후 다듬을 예정입니다.")
                        .font(.caption)
                        .foregroundStyle(palette.secondaryText)
                    Divider()
                    Text(storeDescription)
                        .font(.subheadline)
                        .lineSpacing(4)
                        .fixedSize(horizontal: false, vertical: true)
                        .textSelection(.enabled)
                    Text("주요 기능").font(.subheadline.bold())
                    featureList(storeFeatures)
                }
                .careCard()

                VStack(alignment: .leading, spacing: 8) {
                    Label("건강한 반려생활을 위한 안내", systemImage: "heart.text.clipboard")
                        .font(.caption.bold())
                    Text("멍냥노트의 정보는 일반적인 반려동물 관리 참고용입니다. 질병 진단, 치료, 처방을 대신하지 않으며, 이상 증상이 있거나 반복될 경우 수의사 상담을 권장합니다.")
                        .font(.caption)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .careCard()
            }
            .foregroundStyle(palette.text)
            .padding(16)
        }
        .background(CareBackground())
        .navigationTitle("앱 정보")
        .navigationBarTitleDisplayMode(.inline)
        .tint(palette.accent)
    }

    private func heading(_ title: String, icon: String) -> some View {
        Label(title, systemImage: icon)
            .font(.headline)
            .accessibilityAddTraits(.isHeader)
    }

    private func featureList(_ items: [String]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(items, id: \.self) { item in
                HStack(alignment: .firstTextBaseline, spacing: 10) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(palette.accent)
                        .accessibilityHidden(true)
                    Text(item)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .font(.subheadline)
            }
        }
    }
}
