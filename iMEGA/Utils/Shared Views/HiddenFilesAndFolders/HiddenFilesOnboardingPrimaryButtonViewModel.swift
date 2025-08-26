import MEGAAnalyticsiOS
import MEGAAppPresentation
import MEGADomain
import MEGAL10n

protocol HiddenFilesOnboardingPrimaryButtonViewModelProtocol {
    var buttonTitle: String { get }
    var buttonAction: (@MainActor () async -> Void) { get }
}

struct HiddenFilesSeeUpgradePlansOnboardingButtonViewModel: HiddenFilesOnboardingPrimaryButtonViewModelProtocol {
    let buttonTitle = Strings.Localizable.seePlans
    let buttonAction: (@MainActor () async -> Void)
    
    init(hideFilesAndFoldersRouter: some HideFilesAndFoldersRouting,
         upgradeSubscriptionRouter: some UpgradeSubscriptionRouting,
         tracker: some AnalyticsTracking) {
        buttonAction = {
            tracker.trackAnalyticsEvent(with: HiddenNodeUpgradeUpgradeButtonPressedEvent())
            hideFilesAndFoldersRouter.dismissOnboarding(animated: true, completion: {
                upgradeSubscriptionRouter.showUpgradeAccount()
            })
        }
    }
}

struct FirstTimeOnboardingPrimaryButtonViewModel: HiddenFilesOnboardingPrimaryButtonViewModelProtocol {
    let buttonTitle = Strings.Localizable.continue
    var buttonAction: (@MainActor () async -> Void) {
        onboard
    }
    
    private let nodes: [NodeEntity]
    private let contentConsumptionUserAttributeUseCase: any ContentConsumptionUserAttributeUseCaseProtocol
    private let hideFilesAndFoldersRouter: any HideFilesAndFoldersRouting
    private let tracker: any AnalyticsTracking
    
    init(nodes: [NodeEntity],
         contentConsumptionUserAttributeUseCase: some ContentConsumptionUserAttributeUseCaseProtocol,
         hideFilesAndFoldersRouter: some HideFilesAndFoldersRouting,
         tracker: some AnalyticsTracking) {
        self.nodes = nodes
        self.contentConsumptionUserAttributeUseCase = contentConsumptionUserAttributeUseCase
        self.hideFilesAndFoldersRouter = hideFilesAndFoldersRouter
        self.tracker = tracker
    }
    
    @MainActor
    private func onboard() async {
        tracker.trackAnalyticsEvent(with: HiddenNodeOnboardingContinueButtonPressedEvent())
        do {
            try await contentConsumptionUserAttributeUseCase.saveSensitiveSetting(onboarded: true)
        } catch {
            MEGALogError("[\(type(of: self))] error saving onboarded setting \(error.localizedDescription)")
        }
        hideFilesAndFoldersRouter.dismissOnboarding(animated: true, completion: nil)
        hideFilesAndFoldersRouter.hideNodes(nodes)
    }
}

struct HiddenFilesCloseOnboardingPrimaryButtonViewModel: HiddenFilesOnboardingPrimaryButtonViewModelProtocol {
    let buttonTitle = Strings.Localizable.close
    let buttonAction: (@MainActor () async -> Void)
    
    init(hideFilesAndFoldersRouter: some HideFilesAndFoldersRouting) {
        buttonAction = {
            hideFilesAndFoldersRouter.dismissOnboarding(animated: true, completion: nil)
        }
    }
}
