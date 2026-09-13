import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject private var themeManager: ThemeManager
    @Environment(\.dismiss) private var dismiss
    let onFinish: (() -> Void)?

    init(onFinish: (() -> Void)? = nil) { self.onFinish = onFinish }

    private var palette: ThemePalette { themeManager.theme.palette }
    private let cards: [(String, String, String)] = [
        ("오늘의 케어를 체크해요", "식사, 산책, 양치처럼 매일 챙길 일을 체크하고 완료 상태를 확인할 수 있어요.", "checkmark.seal.fill"),
        ("하루 기록을 남겨요", "식사량, 산책 시간, 증상, 병원 방문, 사진까지 한곳에 기록할 수 있어요.", "square.and.pencil"),
        ("영양제와 알림을 관리해요", "영양제 급여량과 시간을 저장하고, 필요한 시간에 알림을 받을 수 있어요.", "pills.fill"),
        ("사진과 리포트를 확인해요", "사진 앨범으로 기록 사진을 모아보고, 월간 리포트로 한 달 케어 흐름을 확인할 수 있어요.", "photo.on.rectangle.angled"),
        ("여러 아이를 함께 관리해요", "강아지와 고양이를 여러 마리 등록하고, 아이별로 기록을 나눠 관리할 수 있어요.", "pawprint.fill")
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                VStack(spacing: 10) {
                    Image(systemName: "pawprint.fill")
                        .font(.system(size: 38))
                        .foregroundStyle(palette.accent)
                        .padding(16)
                        .background(palette.accent.opacity(0.12), in: Circle())
                    Text("멍냥노트에 오신 걸 환영해요")
                        .font(.title2.bold())
                    Text("우리 아이의 하루를 쉽고 따뜻하게 기록해요")
                        .font(.subheadline)
                        .foregroundStyle(palette.secondaryText)
                }
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.vertical, 8)

                ForEach(cards, id: \.0) { title, description, icon in
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: icon)
                            .font(.title3)
                            .foregroundStyle(palette.accent)
                            .frame(width: 42, height: 42)
                            .background(palette.accent.opacity(0.12), in: RoundedRectangle(cornerRadius: 14))
                        VStack(alignment: .leading, spacing: 5) {
                            Text(title).font(.headline)
                            Text(description)
                                .font(.subheadline)
                                .foregroundStyle(palette.secondaryText)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .careCard()
                }

                Text("펫상식과 기록 기능은 일반 참고용이며, 이상 증상이 반복되면 수의사 상담을 권장해요.")
                    .font(.caption)
                    .foregroundStyle(palette.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
                    .careCard()
            }
            .foregroundStyle(palette.text)
            .padding(20)
        }
        .background(CareBackground())
        .safeAreaInset(edge: .bottom) {
            Button(onFinish == nil ? "닫기" : "시작하기") {
                if let onFinish { onFinish() } else { dismiss() }
            }
            .appPrimaryButton()
            .frame(minHeight: 52)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(palette.background)
        }
        .navigationTitle("처음 사용 안내")
        .navigationBarTitleDisplayMode(.inline)
    }
}
