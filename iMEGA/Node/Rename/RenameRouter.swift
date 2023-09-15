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
    private let renameUseCase: any RenameUseCaseProtocol

    init(
        presenter: UIViewController,
        type: RenameType,
        renameUseCase: any RenameUseCaseProtocol
    ) {
        self.presenter = presenter
        self.type = type
        self.renameUseCase = renameUseCase
    }
    
    func build() -> UIViewController {
        let vm = RenameViewModel(
            router: self,
            type: type,
            renameUseCase: renameUseCase
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
