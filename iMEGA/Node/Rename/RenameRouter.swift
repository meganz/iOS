import DeviceCenter
import MEGADomain
import MEGAPresentation

enum RenameType {
    case device(renameEntity: RenameActionEntity)
}

final class RenameRouter: Routing, RenameViewRouting {
    private weak var presenter: UIViewController?
    private weak var baseViewController: UIViewController?
    private let type: RenameType
    private let nodeActionUseCase: any NodeActionUseCaseProtocol

    init(
        presenter: UIViewController,
        type: RenameType,
        nodeActionUseCase: any NodeActionUseCaseProtocol
    ) {
        self.presenter = presenter
        self.type = type
        self.nodeActionUseCase = nodeActionUseCase
    }
    
    func build() -> UIViewController {
        let vm = RenameViewModel(
            router: self,
            type: type,
            nodeActionUseCase: nodeActionUseCase
        )
        
        let renameAlertController = RenameAlertController(
            title: nil,
            message: nil,
            preferredStyle: .alert
        )
        
        renameAlertController.viewModel = vm
        renameAlertController.configView()
        
        return renameAlertController
    }
    
    func start() {
        let viewController = build()
        baseViewController = viewController
        
        presenter?.present(viewController, animated: true)
    }
    
    func renamingFinishedSuccessfully() {
        switch type {
        case .device(let entity):
            entity.renamingFinished()
        }
    }
    
    func renamingFinishedWithError() {}
}
