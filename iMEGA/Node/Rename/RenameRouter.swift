import DeviceCenter
import MEGADomain
import MEGAPresentation

struct RenameRouter: Routing, RenameViewRouting, Sendable {
    private weak var presenter: UIViewController?
    private let renameEntity: RenameActionEntity
    private let renameUseCase: any RenameUseCaseProtocol

    init(
        presenter: UIViewController,
        renameEntity: RenameActionEntity,
        renameUseCase: some RenameUseCaseProtocol
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
        presenter?.present(viewController, animated: true)
    }
    
    func renamingFinished(with result: Result<Void, any Error>) {
        renameEntity.renamingFinished()
    }
}
