import DeviceCenter
import MEGAAppPresentation
import SwiftUI

protocol ResourceInfoViewRouting: Routing {
    func dismiss()
}

final class ResourceInfoViewRouter: ResourceInfoViewRouting {
    private weak var presenter: UIViewController?
    private weak var baseViewController: UIViewController?
    private let infoModel: ResourceInfoModel
    
    init(
        presenter: UIViewController,
        infoModel: ResourceInfoModel
    ) {
        self.presenter = presenter
        self.infoModel = infoModel
    }
    
    func build() -> UIViewController {
        let vm = ResourceInfoViewModel(
            infoModel: infoModel,
            router: self
        )
        
        let infoView = ResourceInfoView(
            viewModel: vm
        )
        
        let hostingController = UIHostingController(rootView: infoView)
        baseViewController = hostingController
        
        return hostingController
    }
    
    func start() {
        presenter?.present(build(), animated: true)
    }
    
    func dismiss() {
        presenter?.dismissView()
    }
}
