import DeviceCenter
import MEGADomain
import MEGAPresentation

final class RenameRouter: Routing, RenameViewRouting {
    private weak var presenter: UIViewController?
    private weak var baseViewController: UIViewController?
    private let renameEntity: RenameActionEntity
    private let renameUseCase: any RenameUseCaseProtocol

    init(
        presenter: UIViewController,
        renameEntity: RenameActionEntity,
        renameUseCase: any RenameUseCaseProtocol
    ) {
        self.presenter = presenter
        self.renameEntity = renameEntity
        self.renameUseCase = renameUseCase
    }
    
    func build() -> UIViewController {
        let vm = RenameViewModel(
            router: self,
            renameEntity: renameEntity,
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
    
    func renamingFinished(with result: Result<Void, any Error>) {
        renameEntity.renamingFinished()
    }
}
