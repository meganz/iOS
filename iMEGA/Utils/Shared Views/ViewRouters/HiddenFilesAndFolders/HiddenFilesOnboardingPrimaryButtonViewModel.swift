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
         upgradeAccountRouter: some UpgradeAccountRouting) {
        buttonAction = {
            hideFilesAndFoldersRouter.dismissOnboarding(animated: true, completion: {
                upgradeAccountRouter.presentUpgradeTVC()
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
    
    init(nodes: [NodeEntity],
         contentConsumptionUserAttributeUseCase: some ContentConsumptionUserAttributeUseCaseProtocol,
         hideFilesAndFoldersRouter: some HideFilesAndFoldersRouting) {
        self.nodes = nodes
        self.contentConsumptionUserAttributeUseCase = contentConsumptionUserAttributeUseCase
        self.hideFilesAndFoldersRouter = hideFilesAndFoldersRouter
    }
    
    @MainActor
    private func onboard() async {
        do {
            try await contentConsumptionUserAttributeUseCase.saveSensitiveSetting(onboarded: true)
        } catch {
            MEGALogError("[\(type(of: self))] error saving onboarded setting \(error.localizedDescription)")
        }
        hideFilesAndFoldersRouter.dismissOnboarding(animated: true, completion: nil)
        hideFilesAndFoldersRouter.hideNodes(nodes)
    }
}
