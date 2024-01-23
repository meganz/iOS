import MEGADomain
import MEGASDKRepo
import SwiftUI
import UIKit

public struct AdsSlotRouter<T: View> {
    private weak var presenter: UIViewController?
    private let adsSlotViewController: any AdsSlotViewControllerProtocol
    private let contentView: T
    private let accountUseCase: any AccountUseCaseProtocol
    
    private class HostingController<S: View>: UIHostingController<AdsSlotView<S>> {
        
        private let onViewAppeared: (() -> Void)?
        
        init(rootView: AdsSlotView<S>, onViewAppeared: (() -> Void)? = nil) {
            self.onViewAppeared = onViewAppeared
            super.init(rootView: rootView)
        }
        
        required dynamic init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        override func viewDidAppear(_ animated: Bool) {
            super.viewDidAppear(animated)
            onViewAppeared?()
        }
    }
    
    public init(
        accountUseCase: some AccountUseCaseProtocol,
        adsSlotViewController: some AdsSlotViewControllerProtocol,
        contentView: T,
        presenter: UIViewController? = nil
    ) {
        self.adsSlotViewController = adsSlotViewController
        self.accountUseCase = accountUseCase
        self.contentView = contentView
        self.presenter = presenter
    }
    
    public func build(onViewAppeared: (() -> Void)? = nil) -> UIViewController {
        let viewModel = AdsSlotViewModel(adsUseCase: AdsUseCase(repository: AdsRepository.newRepo),
                                         accountUseCase: accountUseCase,
                                         adsSlotChangeStream: AdsSlotChangeStream(adsSlotViewController: adsSlotViewController))
        let adsSlotView = AdsSlotView(viewModel: viewModel, contentView: contentView)
        return HostingController(
            rootView: adsSlotView,
            onViewAppeared: onViewAppeared)
    }
    
    public func start() {
        presenter?.present(build(), animated: true)
    }
}
