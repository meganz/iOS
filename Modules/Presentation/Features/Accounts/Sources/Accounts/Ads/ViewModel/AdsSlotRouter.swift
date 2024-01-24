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
        
        private var onViewFirstAppeared: (() -> Void)?
        
        init(rootView: AdsSlotView<S>, onViewFirstAppeared: (() -> Void)? = nil) {
            self.onViewFirstAppeared = onViewFirstAppeared
            super.init(rootView: rootView)
        }
        
        required dynamic init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        override func viewDidAppear(_ animated: Bool) {
            super.viewDidAppear(animated)
            onViewFirstAppeared?()
            onViewFirstAppeared = nil
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
    
    public func build(onViewFirstAppeared: (() -> Void)? = nil) -> UIViewController {
        let viewModel = AdsSlotViewModel(adsUseCase: AdsUseCase(repository: AdsRepository.newRepo),
                                         accountUseCase: accountUseCase,
                                         adsSlotChangeStream: AdsSlotChangeStream(adsSlotViewController: adsSlotViewController))
        let adsSlotView = AdsSlotView(viewModel: viewModel, contentView: contentView)
        return HostingController(
            rootView: adsSlotView,
            onViewFirstAppeared: onViewFirstAppeared)
    }
    
    public func start() {
        presenter?.present(build(), animated: true)
    }
}
