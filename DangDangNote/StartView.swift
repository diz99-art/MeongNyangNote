import SwiftUI

struct StartView: View {
    @EnvironmentObject private var themeManager: ThemeManager
    @EnvironmentObject private var petStore: PetProfileStore
    let openRecords: () -> Void
    let openSupplements: () -> Void
    let openTips: () -> Void
    let openManagement: () -> Void

    private var palette: ThemePalette { themeManager.theme.palette }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 10) {
                    Image(systemName: "pawprint.fill")
                        .font(.system(size: 38))
                        .foregroundStyle(palette.accent)
                        .padding(14)
                        .background(palette.accent.opacity(0.12), in: Circle())
                    Text("멍냥노트").font(.largeTitle.bold())
                    Text("우리 아이의 하루를 쉽고 따뜻하게")
                        .font(.headline)
                    Text("오늘도 작은 기록으로 소중한 하루를 남겨요.")
                        .font(.subheadline)
                        .foregroundStyle(palette.secondaryText)
                }
                .fixedSize(horizontal: false, vertical: true)
                .padding(.vertical, 8)

                NavigationLink {
                    DogProfileView()
                } label: {
                    HStack(spacing: 14) {
                        DogProfileImage(size: 64)
                        VStack(alignment: .leading, spacing: 5) {
                            Text(petStore.selectedPet?.name ?? "우리 아이").font(.title3.bold())
                            Text("반려동물 선택 · 프로필 보기")
                                .font(.caption).foregroundStyle(palette.secondaryText)
                        }
                        Spacer(minLength: 0)
                        Image(systemName: "chevron.right").font(.caption.bold())
                    }
                    .careCard()
                }
                .buttonStyle(.plain)

                NavigationLink {
                    HomeView()
                } label: {
                    shortcut("오늘의 케어", subtitle: "케어 체크 · 한 줄 메모 · 산책 타이머", icon: "checkmark.seal.fill")
                }
                .buttonStyle(.plain)

                Text("무엇을 해볼까요?").font(.headline)
                Button(action: openRecords) {
                    shortcut("기록 보기", subtitle: "기록과 캘린더를 확인해요", icon: "list.bullet.clipboard")
                }
                Button(action: openSupplements) {
                    shortcut("영양제", subtitle: "급여와 알림을 챙겨요", icon: "pills.fill")
                }
                Button(action: openTips) {
                    shortcut("펫상식", subtitle: "반려생활에 필요한 정보를 살펴봐요", icon: "lightbulb.fill")
                }
                Button(action: openManagement) {
                    shortcut("관리", subtitle: "사진 앨범 · 월간 리포트 · 앱 설정", icon: "gearshape.fill")
                }
            }
            .buttonStyle(.plain)
            .foregroundStyle(palette.text)
            .padding(20)
        }
        .background(CareBackground())
        .navigationTitle("홈")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func shortcut(_ title: String, subtitle: String, icon: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(palette.accent)
                .frame(width: 42, height: 42)
                .background(palette.accent.opacity(0.12), in: RoundedRectangle(cornerRadius: 14))
            VStack(alignment: .leading, spacing: 5) {
                Text(title).font(.headline)
                Text(subtitle).font(.caption).foregroundStyle(palette.secondaryText)
            }
            .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
            Image(systemName: "chevron.right").font(.caption.bold())
        }
        .careCard()
        .contentShape(RoundedRectangle(cornerRadius: 22))
    }
}
