import Accounts
import MEGAAnalytics
import MEGAAppPresentation
import MEGAAssets
import MEGAAuthentication
import MEGAAuthenticationOrchestration
import MEGAL10n
import MEGAPermissions
import MEGAPresentation
import MEGASwiftUI
import SwiftUI

extension AppDelegate {
    @objc func injectAuthenticationDependencies() {
        guard DIContainer.featureFlagProvider.isFeatureFlagEnabled(for: .loginRegisterAndOnboardingRevamp) else { return }

        MEGAAuthentication.DependencyInjection.sharedSdk = .shared
        MEGAAuthentication.DependencyInjection.keychainServiceName = "MEGA"
        MEGAAuthentication.DependencyInjection.keychainAccount = "sessionV3"
        
        MEGAAuthentication.DependencyInjection.loginUseCase = LoginWithPostActionsUseCase(
            loginUseCase: LoginUseCase(
                fetchNodesEnabled: false,
                shouldIncludeFastLoginTimeout: false,
                updateDuplicateSession: true,
                loginAPIRepository: MEGAAuthentication.DependencyInjection.loginAPIRepository,
                loginStoreRepository: MEGAAuthentication.DependencyInjection.loginStoreRepository),
            postLoginActions: [AppDelegatePostLoginAction(appDelegate: self)])

        MEGAAuthentication.DependencyInjection.analyticsTracker = AnalyticsTrackerAdapter()
    }
    
    @objc func makeOnboardingViewController() -> UIViewController {
        if  DIContainer.featureFlagProvider.isFeatureFlagEnabled(for: .loginRegisterAndOnboardingRevamp) {
            makeNewOnboardingViewController()
        } else {
            OnboardingViewController.instantiateOnboarding(with: .default)
        }
    }
    
    @objc func isRootViewNewOnboarding() -> Bool {
        window.rootViewController is UIHostingController<OnboardingView<LoadingSpinner>>
    }
    
    @MainActor
    @objc func showLoadingView(permissionsPending: Bool) {
        var viewController: UIViewController?
        if permissionsPending {
            viewController = AppLoadingViewRouter {
                guard let launchViewController = UIStoryboard(
                    name: "Launch",
                    bundle: nil
                ).instantiateViewController(
                    withIdentifier: "InitialLaunchViewControllerID"
                ) as? InitialLaunchViewController else {
                    return
                }
                launchViewController.delegate = UIApplication.shared.delegate as? any LaunchViewControllerDelegate
                guard let window = UIApplication.shared.keyWindow else {
                    return
                }
                launchViewController.showViews = true
                window.rootViewController = launchViewController
            }.build()
        } else {
            viewController = AppLoadingViewRouter {
                guard let launchViewController = UIStoryboard(
                    name: "Launch",
                    bundle: nil
                ).instantiateViewController(
                    withIdentifier: "LaunchViewControllerID"
                ) as? LaunchViewController else {
                    return
                }
                launchViewController.delegate = UIApplication.shared.delegate as? any LaunchViewControllerDelegate
                launchViewController.delegate.setupFinished()
                launchViewController.delegate.readyToShowRecommendations()
            }
            .build()
        }
        
        guard let window = UIApplication.shared.keyWindow else { return }
        window.rootViewController = viewController
    }
    
    @objc func handlePostLoginSetup() {
        postLoginNotification()
        initProviderDelegate()
        registerForNotifications()
        
        MEGASdk.shared.fetchNodes()
        
        QuickAccessWidgetManager.reloadAllWidgetsContent()
        
        MEGAPurchase.sharedInstance().requestPricing()
    }
    
    @objc func isOnboardingViewControllerAlreadyShown() -> Bool {
        if  DIContainer.featureFlagProvider.isFeatureFlagEnabled(for: .loginRegisterAndOnboardingRevamp) {
            isRootViewNewOnboarding()
        } else {
            window.rootViewController is OnboardingViewController
        }
    }
    
    // MARK: - Private Functions 
    
    private func makeNewOnboardingViewController() -> UIViewController {
        let viewModel = MEGAAuthentication.DependencyInjection.onboardingViewModel
        routeToLoadingSubscription = viewModel.$route
            .receive(on: DispatchQueue.main)
            .filter { $0?.isLoggedIn == true }
            .prefix(1)
            .sink { [weak self] _ in
                self?.routeToLoadingSubscription = nil
                
                Task { @MainActor in
                    let permissionHandler = DevicePermissionsHandler.makeHandler()
                    let shouldSetupPermissions = await permissionHandler.shouldSetupPermissions()
                    self?.showLoadingView(permissionsPending: shouldSetupPermissions)
                }
            }
        
        let view = OnboardingView(
            viewModel: viewModel,
            configuration: .init(
                carousel: .init(
                    displayMode: .largeImage,
                    carouselContent: makeCarouselContent()),
                buttonConfiguration: .init(loginTitle: Strings.Localizable.login))) {
                LoadingSpinner()
            }
        return UIHostingController(rootView: view)
    }
    
    private func makeCarouselContent() -> [OnboardingCarouselContent] {
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

private struct AppDelegatePostLoginAction: PostLoginAction {
    let appDelegate: AppDelegate
    
    @MainActor
    func handlePostLogin() async throws {
        appDelegate.setAccountFirstLogin()
        appDelegate.handlePostLoginSetup()
    }
}

private struct AnalyticsTrackerAdapter: MEGAAnalyticsTrackerProtocol {
    private let tracker: any MEGAAppPresentation.AnalyticsTracking

    init(tracker: some MEGAAppPresentation.AnalyticsTracking = DIContainer.tracker) {
        self.tracker = tracker
    }

    func trackAnalyticsEvent(with event: some MEGAAnalytics.AnalyticsEventEntityProtocol) {
        guard let identifer = event.identifier else { return }
        tracker.trackAnalyticsEvent(with: identifer)
    }
}
