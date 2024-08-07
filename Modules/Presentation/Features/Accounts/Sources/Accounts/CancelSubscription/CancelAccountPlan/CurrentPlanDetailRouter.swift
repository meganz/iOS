import MEGADomain
import MEGAPresentation
import MEGASwift
import StoreKit
import SwiftUI

public protocol CancelAccountPlanRouting: Routing {
    func dismiss()
    func showCancellationSteps()
}

public final class CancelAccountPlanRouter: CancelAccountPlanRouting {
    private weak var baseViewController: UIViewController?
    private weak var presenter: UIViewController?
    private let accountDetails: AccountDetailsEntity
    private let currentPlan: PlanEntity
    private let assets: CancelAccountPlanAssets
    private let featureFlagProvider: any FeatureFlagProviderProtocol
    
    private var appleIDSubscriptionsURL: URL? {
        URL(string: "https://apps.apple.com/account/subscriptions")
    }
    
    public init(
        accountDetails: AccountDetailsEntity,
        currentPlan: PlanEntity,
        assets: CancelAccountPlanAssets,
        presenter: UIViewController,
        featureFlagProvider: some FeatureFlagProviderProtocol = DIContainer.featureFlagProvider
    ) {
        self.accountDetails = accountDetails
        self.currentPlan = currentPlan
        self.assets = assets
        self.presenter = presenter
        self.featureFlagProvider = featureFlagProvider
    }
    
    public func build() -> UIViewController {
        let featureListHelper = FeatureListHelper(
            account: accountDetails,
            currentPlan: currentPlan,
            assets: assets
        )
        
        let viewModel = CancelAccountPlanViewModel(
            currentPlanName: accountDetails.proLevel.toAccountTypeDisplayName(),
            currentPlanStorageUsed: String.memoryStyleString(fromByteCount: accountDetails.storageUsed),
            featureListHelper: featureListHelper, 
            tracker: DIContainer.tracker,
            router: self
        )
        
        let hostingController = UIHostingController(
            rootView: CancelAccountPlanView(viewModel: viewModel)
        )
        baseViewController = hostingController
        return hostingController
    }
    
    public func start() {
        let viewController = build()
        presenter?.present(viewController, animated: true)
    }
    
    public func dismiss() {
        presenter?.dismiss(animated: true)
    }
    
    public func showCancellationSteps() {
        guard let billedPlan = accountDetails.plans.first(where: { $0.isProPlan }),
              let currentSubscription = accountDetails.subscriptions.first(where: { $0.id == billedPlan.subscriptionId }) else { return }
        
        switch currentSubscription.paymentMethodId {
        case .itunes:
            isCancellationSurveyEnabled ? showCancellationSurvey() : showAppleManageSubscriptions()
        case .googleWallet: showGoogleCancellationSteps()
        default: showWebClientCancellationSteps()
        }
    }
    
    private var isCancellationSurveyEnabled: Bool {
        featureFlagProvider.isFeatureFlagEnabled(for: .subscriptionCancellationSurvey)
    }
    
    private func showGoogleCancellationSteps() {
        CancelSubscriptionStepsRouter(
            type: .google,
            presenter: baseViewController
        ).start()
    }

    private func showWebClientCancellationSteps() {
        CancelSubscriptionStepsRouter(
            type: .webClient,
            presenter: baseViewController
        ).start()
    }

    private func showCancellationSurvey() {
        CancellationSurveyRouter(
            presenter: baseViewController
        ).start()
    }
    
    private func showAppleManageSubscriptions() {
        guard let scene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first(where: { $0.activationState == .foregroundActive }),
              !ProcessInfo.processInfo.isiOSAppOnMac else {
            openAppleIDSubscriptionsPage()
            return
        }
        
        Task {
            do {
                try await AppStore.showManageSubscriptions(in: scene)
            } catch {
                openAppleIDSubscriptionsPage()
            }
        }
    }
    
    private func openAppleIDSubscriptionsPage() {
        guard let url = appleIDSubscriptionsURL else { return }
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }
}
