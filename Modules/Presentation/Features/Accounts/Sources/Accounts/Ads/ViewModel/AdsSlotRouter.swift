import MEGADomain
import MEGASDKRepo
import MEGASwiftUI
import SwiftUI
import UIKit

@MainActor
public struct AdsSlotRouter<T: View> {
    private weak var presenter: UIViewController?
    private let adsSlotViewController: any AdsSlotViewControllerProtocol
    private let accountUseCase: any AccountUseCaseProtocol
    private let contentView: T
    private let presentationStyle: UIModalPresentationStyle
    
    public init(
        adsSlotViewController: some AdsSlotViewControllerProtocol,
        accountUseCase: some AccountUseCaseProtocol,
        contentView: T,
        presenter: UIViewController? = nil,
        presentationStyle: UIModalPresentationStyle = .automatic
    ) {
        self.adsSlotViewController = adsSlotViewController
        self.accountUseCase = accountUseCase
        self.contentView = contentView
        self.presenter = presenter
        self.presentationStyle = presentationStyle
    }
    
    public func build(onViewFirstAppeared: (() -> Void)? = nil) -> UIViewController {
        let viewModel = AdsSlotViewModel(
            adsSlotUpdatesProvider: AdsSlotUpdatesProvider(adsSlotViewController: adsSlotViewController),
            accountUseCase: accountUseCase
        )
        
        let adsSlotView = AdsSlotView(viewModel: viewModel, contentView: contentView)
            .onFirstAppear(perform: onViewFirstAppeared)
        
        let adsViewController = UIHostingController(rootView: adsSlotView)
        adsViewController.modalPresentationStyle = presentationStyle
        
        return adsViewController
    }
    
    public func start() {
        presenter?.present(build(), animated: true)
    }
}
