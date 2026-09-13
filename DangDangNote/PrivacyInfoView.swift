import SwiftUI

struct PrivacyInfoView: View {
    @EnvironmentObject private var themeManager: ThemeManager

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                infoCard("데이터 저장 방식", icon: "internaldrive.fill",
                         text: "멍냥노트의 기록 데이터는 기본적으로 사용자의 기기 안에 저장됩니다.")
                infoCard("사진 데이터", icon: "photo.fill",
                         text: "사용자가 선택한 사진만 앱 기록에 저장됩니다.")
                infoCard("알림", icon: "bell.fill",
                         text: "영양제 알림은 사용자가 설정한 시간에 기기 알림으로 제공됩니다.")
                infoCard("서버 전송", icon: "lock.shield.fill",
                         text: "현재 버전에서는 별도의 서버로 데이터를 전송하지 않습니다.")
                infoCard("백업 파일", icon: "externaldrive.fill",
                         text: "백업 기능을 사용할 경우 사용자가 직접 선택한 위치로 백업 파일을 저장하거나 공유할 수 있습니다.")
                VStack(alignment: .leading, spacing: 8) {
                    Label("참고해 주세요", systemImage: "heart.text.clipboard")
                        .font(.caption.bold())
                    Text("펫상식과 기록 기능은 일반적인 참고용이며, 진단이나 치료를 대신하지 않습니다. 이상 증상이 반복되면 수의사 상담을 권장합니다.")
                        .font(.caption)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .careCard()
            }
            .foregroundStyle(themeManager.theme.palette.text)
            .padding(16)
        }
        .background(CareBackground())
        .navigationTitle("개인정보 안내")
        .navigationBarTitleDisplayMode(.inline)
        .tint(themeManager.theme.palette.accent)
    }

    private func infoCard(_ title: String, icon: String, text: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundStyle(themeManager.theme.palette.accent)
                    .accessibilityHidden(true)
                Text(title)
            }
            .font(.headline)
            .accessibilityAddTraits(.isHeader)
            Text(text)
                .font(.subheadline)
                .fixedSize(horizontal: false, vertical: true)
        }
        .careCard()
    }
}
