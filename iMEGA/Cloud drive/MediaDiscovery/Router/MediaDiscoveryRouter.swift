import UIKit
import MEGADomain
import MEGAPresentation

@objc final class MediaDiscoveryRouter: NSObject, Routing {
    private weak var presenter: UIViewController?
    private let parentNode: MEGANode
    
    @objc init(viewController: UIViewController?, parentNode: MEGANode) {
        self.presenter = viewController
        self.parentNode = parentNode
        
        super.init()
    }
    
    func build() -> UIViewController {
        let parentNode = parentNode.toNodeEntity()
        let analyticsUseCase = MediaDiscoveryAnalyticsUseCase(repository: AnalyticsRepository.newRepo)
        let mediaDiscoveryUseCase = MediaDiscoveryUseCase(mediaDiscoveryRepository: MediaDiscoveryRepository.newRepo,
                                                          nodeUpdateRepository: NodeUpdateRepository.newRepo)
        let viewModel = MediaDiscoveryViewModel(parentNode: parentNode, router: self, analyticsUseCase: analyticsUseCase,
                                                mediaDiscoveryUseCase: mediaDiscoveryUseCase)
        return MediaDiscoveryViewController(viewModel: viewModel, folderName: parentNode.name)
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
