import Combine
import MEGAAssets
import MEGAAuthentication
import MEGAL10n
import MEGASwiftUI
import SwiftUI

final class OnboardingUSPViewController: UIHostingController<OnboardingView<LoadingSpinner>> {
    private let viewModel: OnboardingRoutingViewModel
    
    init(
        viewModel: OnboardingViewModel = MEGAAuthentication.DependencyInjection.onboardingViewModel
    ) {
        self.viewModel = .init(
            onboardingViewModel: viewModel,
            permissionAppLaunchRouter: PermissionAppLaunchRouter())
        super.init(rootView: OnboardingView(
            viewModel: self.viewModel.onboardingViewModel,
            configuration: .welcome,
            loadingView: {
                LoadingSpinner()
            }))
    }
    
    @MainActor required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func presentLoginView(email: String? = nil) {
        viewModel.presentLoginView(email: email)
    }
}

private extension OnboardingConfiguration {
    static var welcome: OnboardingConfiguration {
        .init(
            carousel: .init(
                displayMode: .largeImage,
                carouselContent: .welcome),
            buttonConfiguration: .init(loginTitle: Strings.Localizable.login))
    }
}

private extension [OnboardingCarouselContent] {
    static var welcome: [OnboardingCarouselContent] {
        [.init(
            title: Strings.Localizable.Onboarding.UniqueSellingProposition.Carousel.Page.First.title,
            subtitle: Strings.Localizable.Onboarding.UniqueSellingProposition.Carousel.Page.First.subtitle,
            image: MEGAAssetsImageProvider.image(
                named: .onboardingCarousel1)),
         .init(
            title: Strings.Localizable.Onboarding.UniqueSellingProposition.Carousel.Page.Second.title,
            subtitle: Strings.Localizable.Onboarding.UniqueSellingProposition.Carousel.Page.Second.subtitle,
            image: MEGAAssetsImageProvider.image(
                named: .onboardingCarousel2)),
         .init(
            title: Strings.Localizable.Onboarding.UniqueSellingProposition.Carousel.Page.Third.title,
            subtitle: Strings.Localizable.Onboarding.UniqueSellingProposition.Carousel.Page.Third.subtitle,
            image: MEGAAssetsImageProvider.image(
                named: .onboardingCarousel3)),
         .init(
            title: Strings.Localizable.Onboarding.UniqueSellingProposition.Carousel.Page.Fourth.title,
            subtitle: Strings.Localizable.Onboarding.UniqueSellingProposition.Carousel.Page.Fourth.subtitle,
            image: MEGAAssetsImageProvider.image(
                named: .onboardingCarousel4))
        ]
    }
}
