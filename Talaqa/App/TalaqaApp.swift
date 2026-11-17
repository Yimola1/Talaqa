import SwiftUI
import SwiftData

@main
struct TalaqaApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(\.layoutDirection, .rightToLeft)
                .tint(Theme.primary)
        }
        .modelContainer(for: [
            UserProfile.self,
            WordCard.self,
            ActivityLog.self,
            MistakeRecord.self,
            LessonCompletion.self
        ])
    }
}

struct RootView: View {
    @Environment(\.modelContext) private var context
    @Query private var profiles: [UserProfile]

    var body: some View {
        Group {
            if let profile = profiles.first {
                if !profile.onboardingDone {
                    OnboardingView(profile: profile)
                } else if !profile.placementDone {
                    PlacementTestView(profile: profile)
                } else {
                    MainTabView(profile: profile)
                }
            } else {
                ProgressView()
                    .onAppear {
                        context.insert(UserProfile())
                        try? context.save()
                    }
            }
        }
        .animation(.easeInOut, value: profiles.first?.onboardingDone)
        .animation(.easeInOut, value: profiles.first?.placementDone)
    }
}

struct MainTabView: View {
    @Bindable var profile: UserProfile

    var body: some View {
        TabView {
            NavigationStack { TodayView(profile: profile) }
                .tabItem { Label("اليوم", systemImage: "sun.max.fill") }
            NavigationStack { LearnView(profile: profile) }
                .tabItem { Label("تعلّم", systemImage: "book.fill") }
            NavigationStack { TutorHomeView(profile: profile) }
                .tabItem { Label("المعلّم", systemImage: "bubble.left.and.bubble.right.fill") }
            NavigationStack { PronunciationHomeView(profile: profile) }
                .tabItem { Label("النطق", systemImage: "waveform") }
            NavigationStack { ProfileView(profile: profile) }
                .tabItem { Label("حسابي", systemImage: "person.crop.circle.fill") }
        }
    }
}
