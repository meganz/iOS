import MEGAAuthentication
import SwiftUI

struct LaunchView: View {
    @StateObject var viewModel: LaunchViewModel

    var body: some View {
        content
            .task { viewModel.onAppear() }
    }

    @ViewBuilder var content: some View {
        switch viewModel.route {
        case .onboarding(let onboardingViewModel):
            onboardingView(onboardingViewModel)
        case .home(let homeViewModel):
            HomeView(viewModel: homeViewModel)
        default:
            splashScreen
        }
    }

    @ViewBuilder func onboardingView(_ viewModel: OnboardingViewModel) -> some View {
        OnboardingView(
            viewModel: viewModel,
            onboardingCarouselContent: [
                OnboardingCarouselContent(
                    title: "Welcome to MEGA Player",
                    subtitle: """
                    A brand new experience for video content streaming on MEGA, with new features and a fresh design.
                    
                    This is just a demo. MEGA Player is a work in progress and does not represent the final product.
                    """,
                    image: Image(.launchScreenAppIcon)
                )
            ]
        ) {
            splashScreen
        }
    }

    var splashScreen: some View {
        SplashScreenView(logo: Image(.launchScreenAppIcon))
    }
}
