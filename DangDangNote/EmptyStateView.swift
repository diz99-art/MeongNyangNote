import SwiftUI

struct EmptyStateView: View {
    @EnvironmentObject private var themeManager: ThemeManager
    let icon: String
    let title: String
    let message: String
    var actionTitle: String?
    var action: (() -> Void)?

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 38))
                .foregroundStyle(themeManager.theme.palette.accent)
            Text(title)
                .font(.headline)
                .foregroundStyle(themeManager.theme.palette.text)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .buttonStyle(.borderedProminent)
                    .tint(themeManager.theme.palette.accent)
                    .padding(.top, 2)
            }
        }
        .frame(maxWidth: .infinity)
        .careCard()
    }
}

