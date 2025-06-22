import Combine
import MEGAAppSDKRepo
import MEGAAssets
import MEGAAuthentication
import MEGADomain
import MEGAL10n
import MEGASwiftUI
import SwiftUI

final class OnboardingUSPViewController: UIHostingController<OnboardingView<LoadingSpinner>> {
    private let viewModel: OnboardingRoutingViewModel
    
    init(
        viewModel: OnboardingViewModel = MEGAAuthentication.DependencyInjection.onboardingViewModel
    ) {
        self.viewModel = .init(onboardingViewModel: viewModel) { hasConfirmedAccount in
            guard let window = UIApplication.shared.keyWindow else { return }
            let accountUseCase = AccountUseCase(repository: AccountRepository.newRepo)
            let coordinator = SubscriptionPurchaseViewCoordinator(
                window: window,
                isNewUserRegistration: hasConfirmedAccount,
                accountUseCase: accountUseCase) {
                    // Note: The fetching/loading of nodes was already done by SubscriptionPurchaseViewCoordinator
                    // Therefore the PermissionAppLaunchRouter doesn't need to show loading screen again.
                    PermissionAppLaunchRouter().setRootViewController(shouldShowLoadingScreen: false)
                }
            coordinator.start()
        }
        
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
    
    func presentSignUpView(email: String? = nil) {
        viewModel.presentSignUpView(email: email)
    }
    
    func presentConfirmEmail(information: NewAccountInformationEntity) {
        viewModel.presentConfirmEmail(information: information)
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
            image: MEGAAssets.Image.onboardingCarousel1),
         .init(
            title: Strings.Localizable.Onboarding.UniqueSellingProposition.Carousel.Page.Second.title,
            subtitle: Strings.Localizable.Onboarding.UniqueSellingProposition.Carousel.Page.Second.subtitle,
            image: MEGAAssets.Image.onboardingCarousel2),
         .init(
            title: Strings.Localizable.Onboarding.UniqueSellingProposition.Carousel.Page.Third.title,
            subtitle: Strings.Localizable.Onboarding.UniqueSellingProposition.Carousel.Page.Third.subtitle,
            image: MEGAAssets.Image.onboardingCarousel3),
         .init(
            title: Strings.Localizable.Onboarding.UniqueSellingProposition.Carousel.Page.Fourth.title,
            subtitle: Strings.Localizable.Onboarding.UniqueSellingProposition.Carousel.Page.Fourth.subtitle,
            image: MEGAAssets.Image.onboardingCarousel4)
        ]
    }
}
