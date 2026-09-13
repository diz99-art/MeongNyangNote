import SwiftUI

/// 앱 시작 동안 표시하는 화면입니다. 저장 데이터나 권한 요청을 다루지 않습니다.
struct SplashView: View {
    @EnvironmentObject private var themeManager: ThemeManager

    private var palette: ThemePalette { themeManager.theme.palette }

    var body: some View {
        ZStack {
            palette.background.ignoresSafeArea()
            VStack(spacing: 18) {
                Image(systemName: "pawprint.fill")
                    .font(.system(size: 58, weight: .medium))
                    .foregroundStyle(palette.accent)
                    .padding(30)
                    .background(palette.accent.opacity(0.12), in: Circle())
                    .accessibilityHidden(true)

                Text("멍냥노트")
                    .font(.system(.largeTitle, design: .rounded, weight: .bold))
                    .foregroundStyle(palette.text)
                    .accessibilityAddTraits(.isHeader)
                Text("우리 아이의 하루를 기록해요")
                    .font(.subheadline)
                    .foregroundStyle(palette.text)
                Text("오늘도 소중한 하루를 남겨요")
                    .font(.caption)
                    .foregroundStyle(palette.secondaryText)
                    .padding(.top, 14)
            }
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
            .padding(24)
        }
    }
}
