import SwiftUI

struct ManagementView: View {
    @EnvironmentObject private var themeManager: ThemeManager
    private var textColor: Color { themeManager.theme.palette.text }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Text("앱 설정과 모아보기 기능을 한곳에서 관리해요")
                    .font(.subheadline)
                    .foregroundStyle(themeManager.theme.palette.secondaryText)
                managementMenuCard
            }
            .padding(16)
        }
        .background(CareBackground())
        .navigationTitle("관리")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var managementMenuCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("관리 메뉴", systemImage: "slider.horizontal.3")
                .font(.headline)
                .foregroundStyle(textColor)

            managementLink("반려동물 프로필", description: "우리 아이의 사진과 기본 정보를 확인해요", icon: "pawprint.fill") {
                DogProfileView()
            }
            managementLink("개인정보 안내", description: "데이터 저장과 이용 안내를 확인해요", icon: "lock.shield.fill") {
                PrivacyInfoView()
            }
            managementLink("사진 앨범", description: "기록에 남긴 사진을 모아봐요", icon: "photo.on.rectangle.angled") {
                PhotoAlbumView()
            }
            managementLink("월간 리포트", description: "한 달 케어 기록을 확인해요", icon: "chart.bar.doc.horizontal") {
                MonthlyReportView()
            }
            managementLink("테마 설정", description: "앱 분위기를 바꿔요", icon: "paintpalette.fill") {
                ThemeSettingsView()
            }
            managementLink("데이터 관리", description: "기록을 백업·복원하거나 초기화해요", icon: "externaldrive.fill") {
                DataManagementView()
            }
            managementLink("처음 사용 안내", description: "멍냥노트의 주요 기능을 다시 확인해요", icon: "questionmark.circle.fill") {
                OnboardingView()
            }
            managementLink("앱 정보", description: "앱 이름과 버전을 확인해요", icon: "info.circle.fill") {
                AppInfoView()
            }
        }
        .careCard()
    }

    private func managementLink<Destination: View>(
        _ title: String,
        description: String,
        icon: String,
        @ViewBuilder destination: () -> Destination
    ) -> some View {
        NavigationLink(destination: destination()) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(themeManager.theme.palette.accent)
                    .frame(width: 28, height: 28)
                    .background(themeManager.theme.palette.accent.opacity(0.12), in: Circle())
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(textColor)
                    Text(description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            .contentShape(Rectangle())
            .padding(.vertical, 7)
        }
        .buttonStyle(.plain)
    }
}

private struct ThemeSettingsView: View {
    @EnvironmentObject private var themeManager: ThemeManager

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text("테마를 선택하면 앱 전체 분위기가 바뀌어요")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                ForEach(AppTheme.allCases) { theme in
                    Button {
                        themeManager.theme = theme
                    } label: {
                        HStack {
                            Circle()
                                .fill(theme.palette.accent)
                                .frame(width: 22, height: 22)
                            Text(theme.title)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(theme.palette.text)
                            Spacer()
                            if themeManager.theme == theme {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(theme.palette.accent)
                            }
                        }
                        .padding(12)
                        .background(theme.palette.card, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                        .overlay {
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .stroke(theme == .modernBlack ? Color.white.opacity(0.22) : .clear, lineWidth: 1)
                        }
                    }
                    .buttonStyle(.plain)
                    .accessibilityValue(themeManager.theme == theme ? "선택됨" : "선택 안 됨")
                }
            }
            .padding(16)
        }
        .background(CareBackground())
        .navigationTitle("테마 설정")
        .navigationBarTitleDisplayMode(.inline)
    }
}
