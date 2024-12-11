import MEGADomain
import MEGAPresentation
import MEGASDKRepo
import MEGASwiftUI
import SwiftUI
import UIKit

@MainActor
public struct AdsSlotRouter<T: View> {
    private weak var presenter: UIViewController?
    private let adsSlotViewController: any AdsSlotViewControllerProtocol
    private let accountUseCase: any AccountUseCaseProtocol
    private let featureFlagProvider: FeatureFlagProviderProtocol
    private let contentView: T
    private let presentationStyle: UIModalPresentationStyle
    
    public init(
        adsSlotViewController: some AdsSlotViewControllerProtocol,
        accountUseCase: some AccountUseCaseProtocol,
        featureFlagProvider: some FeatureFlagProviderProtocol,
        contentView: T,
        presenter: UIViewController? = nil,
        presentationStyle: UIModalPresentationStyle = .automatic
    ) {
        self.adsSlotViewController = adsSlotViewController
        self.accountUseCase = accountUseCase
        self.featureFlagProvider = featureFlagProvider
        self.contentView = contentView
        self.presenter = presenter
        self.presentationStyle = presentationStyle
    }
    
    public func build(onViewFirstAppeared: (() -> Void)? = nil) -> UIViewController {
        let viewModel = AdsSlotViewModel(
            adsSlotUpdatesProvider: AdsSlotUpdatesProvider(adsSlotViewController: adsSlotViewController),
            localFeatureFlagProvider: featureFlagProvider,
            accountUseCase: accountUseCase,
            onViewFirstAppeared: onViewFirstAppeared
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
