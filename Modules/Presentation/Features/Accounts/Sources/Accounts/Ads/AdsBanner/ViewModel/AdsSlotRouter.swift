import MEGAAppPresentation
import MEGAAppSDKRepo
import MEGADomain
import MEGAPreference
import MEGARepo
import MEGASwiftUI
import SwiftUI
import UIKit

@MainActor
public struct AdsSlotRouter<T: View> {
    private weak var presenter: UIViewController?
    private let adsSlotViewController: any AdsSlotViewControllerProtocol
    private let accountUseCase: any AccountUseCaseProtocol
    private let purchaseUseCase: any AccountPlanPurchaseUseCaseProtocol
    private let nodeUseCase: (any NodeUseCaseProtocol)?
    private let contentView: T
    private let presentationStyle: UIModalPresentationStyle
    private let publicLink: String?
    private let isFolderLink: Bool
    
    public init(
        adsSlotViewController: some AdsSlotViewControllerProtocol,
        accountUseCase: some AccountUseCaseProtocol,
        purchaseUseCase: some AccountPlanPurchaseUseCaseProtocol,
        nodeUseCase: (any NodeUseCaseProtocol)? = nil,
        contentView: T,
        presenter: UIViewController? = nil,
        presentationStyle: UIModalPresentationStyle = .automatic,
        publicLink: String? = nil,
        isFolderLink: Bool = false
    ) {
        self.adsSlotViewController = adsSlotViewController
        self.accountUseCase = accountUseCase
        self.purchaseUseCase = purchaseUseCase
        self.nodeUseCase = nodeUseCase
        self.contentView = contentView
        self.presenter = presenter
        self.presentationStyle = presentationStyle
        self.publicLink = publicLink
        self.isFolderLink = isFolderLink
    }
    
    public func build(
        onViewFirstAppeared: (() -> Void)? = nil,
        adsFreeViewProPlanAction: (() -> Void)? = nil
    ) -> UIViewController {
        let viewModel = AdsSlotViewModel(
            adsSlotUpdatesProvider: AdsSlotUpdatesProvider(adsSlotViewController: adsSlotViewController),
            adsUseCase: AdsUseCase(repository: AdsRepository.newRepo),
            nodeUseCase: nodeUseCase,
            accountUseCase: accountUseCase,
            purchaseUseCase: purchaseUseCase,
            preferenceUseCase: PreferenceUseCase.default,
            onViewFirstAppeared: onViewFirstAppeared,
            adsFreeViewProPlanAction: adsFreeViewProPlanAction,
            publicNodeLink: publicLink,
            isFolderLink: isFolderLink
        )
        
        let adsSlotView = AdsSlotView(viewModel: viewModel, contentView: contentView)
        
        let adsViewController = UIHostingController(rootView: adsSlotView)
        adsViewController.modalPresentationStyle = presentationStyle
        
        return adsViewController
    }
    
    public func start() {
        presenter?.present(build(), animated: true)
    }
}
