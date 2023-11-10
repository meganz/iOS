import MEGADomain
import MEGASDKRepo
import SwiftUI
import UIKit

public struct AdsSlotRouter<T: View> {
    private weak var presenter: UIViewController?
    private let adsSlotViewController: any AdsSlotViewControllerProtocol
    private let contentView: T
    private let accountUseCase: any AccountUseCaseProtocol
    
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
    
    public func build() -> UIViewController {
        let viewModel = AdsSlotViewModel(adsUseCase: AdsUseCase(repository: AdsRepository.newRepo), 
                                         accountUseCase: accountUseCase,
                                         adsSlotChangeStream: AdsSlotChangeStream(adsSlotViewController: adsSlotViewController))
        let adsSlotView = AdsSlotView(viewModel: viewModel, contentView: contentView)
        return UIHostingController(rootView: adsSlotView)
    }
    
    public func start() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            presenter?.present(build(), animated: true)
        }
    }
}
