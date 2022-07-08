import UIKit

@available(iOS 14.0, *)
@objc final class MediaDiscoveryRouter: NSObject, Routing {
    private weak var presenter: UIViewController?
    private let parentNode: MEGANode
    
    @objc init(viewController: UIViewController?, parentNode: MEGANode) {
        self.presenter = viewController
        self.parentNode = parentNode
        
        super.init()
    }
    
    func build() -> UIViewController {
        let usecase = MediaDiscoveryStatsUseCase(repository: StatsRepository.newRepo)
        let viewModel = MediaDiscoveryViewModel(parentNode: parentNode, router: self, statsUseCase: usecase)
        let vc = MediaDiscoveryViewController(viewModel: viewModel, folderName: parentNode.name ?? "")
        
        return vc
    }
    
    func start() {
        guard let presenter = presenter else {
            MEGALogDebug("Unable to start Media Discovery Screen as presented controller is nil")
            return
        }
        
        let nav = MEGANavigationController(rootViewController: build())
        nav.modalPresentationStyle = .fullScreen
        presenter.present(nav, animated: true, completion: nil)
    }
}
