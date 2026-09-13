import SwiftUI

enum AppTextColor: String, CaseIterable, Identifiable {
    case black, brown, orange, blue, pink

    var id: String { rawValue }
    var title: String {
        switch self {
        case .black: return "검정"
        case .brown: return "브라운"
        case .orange: return "피치"
        case .blue: return "블루"
        case .pink: return "핑크"
        }
    }
    var color: Color {
        switch self {
        case .black: return .primary
        case .brown: return .brown
        case .orange: return Color(red: 0.96, green: 0.70, blue: 0.72)
        case .blue: return .blue
        case .pink: return .pink
        }
    }
}

struct ThemePalette {
    let background: Color
    let card: Color
    let accent: Color
    let text: Color
    let secondaryText: Color
}

enum AppTheme: String, CaseIterable, Identifiable {
    case cream, mint, lavender, modernBlack, pink

    var id: String { rawValue }
    var title: String {
        switch self {
        case .cream: return "크림"
        case .mint: return "민트"
        case .lavender: return "라벤더"
        case .modernBlack: return "모던 블랙"
        case .pink: return "핑크"
        }
    }
    var palette: ThemePalette {
        switch self {
        case .cream: return ThemePalette(background: Color(red: 0.98, green: 0.96, blue: 0.91), card: Color(red: 1.0, green: 0.99, blue: 0.97), accent: Color(red: 0.40, green: 0.68, blue: 0.62), text: Color(red: 0.20, green: 0.18, blue: 0.16), secondaryText: .secondary)
        case .mint: return ThemePalette(background: Color(red: 0.91, green: 0.97, blue: 0.94), card: .white, accent: .mint, text: Color(.darkGray), secondaryText: .secondary)
        case .lavender: return ThemePalette(background: Color(red: 0.95, green: 0.92, blue: 0.98), card: .white, accent: .purple, text: Color(red: 0.20, green: 0.16, blue: 0.24), secondaryText: .secondary)
        case .modernBlack: return ThemePalette(background: Color(red: 0.07, green: 0.07, blue: 0.08), card: Color(red: 0.14, green: 0.14, blue: 0.16), accent: .white, text: .white, secondaryText: Color(.lightGray))
        case .pink: return ThemePalette(background: Color(red: 1.0, green: 0.94, blue: 0.96), card: .white, accent: .pink, text: Color(.darkGray), secondaryText: .secondary)
        }
    }
}

final class ThemeManager: ObservableObject {
    @Published var theme: AppTheme {
        didSet { UserDefaults.standard.set(theme.rawValue, forKey: "selectedTheme") }
    }

    init() {
        theme = AppTheme(rawValue: UserDefaults.standard.string(forKey: "selectedTheme") ?? "mint") ?? .mint
    }
}

struct ContentView: View {
    @StateObject private var themeManager = ThemeManager()
    @StateObject private var petStore = PetProfileStore()
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @State private var navigationPaths = [NavigationPath(), NavigationPath(), NavigationPath(), NavigationPath()]
    @State private var selectedTab = 0

    var body: some View {
        Group {
            if hasSeenOnboarding { mainTabs }
            else { OnboardingView { hasSeenOnboarding = true } }
        }
        .tint(themeManager.theme.palette.accent)
        .environmentObject(themeManager)
        .environmentObject(petStore)
        .preferredColorScheme(themeManager.theme == .modernBlack ? .dark : .light)
    }

    private var mainTabs: some View {
        TabView(selection: $selectedTab) {
            NavigationStack(path: $navigationPaths[0]) {
                HomeView()
            }
            .tabItem {
                Label("홈", systemImage: "house")
            }
            .tag(0)

            NavigationStack(path: $navigationPaths[1]) {
                HistoryView()
            }
            .tabItem {
                Label("기록", systemImage: "list.bullet.clipboard")
            }
            .tag(1)

            NavigationStack(path: $navigationPaths[2]) {
                SupplementCheckView()
            }
            .tabItem {
                Label("영양제", systemImage: "pills")
            }
            .tag(2)

            NavigationStack(path: $navigationPaths[3]) {
                PetTipsView()
            }
            .tabItem {
                Label("펫상식", systemImage: "lightbulb.fill")
            }
            .tag(3)

        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View { ContentView() }
}

// 화면마다 같은 카드 여백과 모서리를 사용합니다.
extension View {
    func careCard() -> some View {
        modifier(ThemeCardModifier())
    }

    func appPrimaryButton() -> some View {
        buttonStyle(AppPrimaryButtonStyle())
    }

    func appSecondaryButton() -> some View {
        buttonStyle(AppSecondaryButtonStyle())
    }
}

struct ThemeCardModifier: ViewModifier {
    @EnvironmentObject private var themeManager: ThemeManager

    func body(content: Content) -> some View {
        let isDark = themeManager.theme == .modernBlack
        content
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                themeManager.theme.palette.card,
                in: RoundedRectangle(cornerRadius: 24, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(isDark ? Color.white.opacity(0.14) : Color.black.opacity(0.045), lineWidth: 1)
            )
            .shadow(color: .black.opacity(isDark ? 0.22 : 0.055), radius: 12, y: 4)
    }
}

struct AppPrimaryButtonStyle: ButtonStyle {
    @EnvironmentObject private var themeManager: ThemeManager

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.semibold))
            .frame(minHeight: 44)
            .frame(maxWidth: .infinity)
            .foregroundStyle(themeManager.theme == .modernBlack ? Color.black : Color.white)
            .background(themeManager.theme.palette.accent, in: Capsule())
            .opacity(configuration.isPressed ? 0.78 : 1)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

struct AppSecondaryButtonStyle: ButtonStyle {
    @EnvironmentObject private var themeManager: ThemeManager

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.semibold))
            .frame(minHeight: 40)
            .foregroundStyle(themeManager.theme.palette.accent)
            .padding(.horizontal, 16)
            .background(themeManager.theme.palette.accent.opacity(0.12), in: Capsule())
            .opacity(configuration.isPressed ? 0.72 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

struct CareBackground: View {
    @EnvironmentObject private var themeManager: ThemeManager

    var body: some View {
        themeManager.theme.palette.background
            .ignoresSafeArea()
    }
}

func recordSymbol(for type: String) -> String {
    switch type {
    case "식사": return "fork.knife"
    case "산책": return "figure.walk"
    case "증상": return "exclamationmark.triangle.fill"
    case "병원": return "cross.case.fill"
    case "몸무게": return "scalemass.fill"
    case "영양제": return "pills.fill"
    default: return "note.text"
    }
}
