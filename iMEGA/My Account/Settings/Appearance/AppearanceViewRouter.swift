import Foundation
import MEGAAppPresentation
import MEGADomain
import MEGARepo
import MEGASDKRepo

struct AppearanceViewRouter: Routing {
    
    private weak var presenter: UINavigationController?
    
    init(presenter: UINavigationController?) {
        self.presenter = presenter
    }
    
    func build() -> UIViewController {
        guard let controller = UIStoryboard(name: "Appearance", bundle: nil)
            .instantiateViewController(identifier: "AppearanceTableViewControllerID", creator: { coder in
                let viewModel = AppearanceViewModel(
                    preferenceUseCase: PreferenceUseCase(
                        repository: PreferenceRepository.newRepo),
                    sensitiveNodeUseCase: SensitiveNodeUseCase(
                        nodeRepository: NodeRepository.newRepo,
                        accountUseCase: AccountUseCase(repository: AccountRepository.newRepo)),
                    contentConsumptionUserAttributeUseCase: ContentConsumptionUserAttributeUseCase(
                        repo: UserAttributeRepository.newRepo))
                return AppearanceTableViewController(coder: coder, viewModel: viewModel) }) as? AppearanceTableViewController else {
            fatalError("AppearanceViewRouter: could not create an instance of AppearanceTableViewController")
        }
        
        return controller
    }
    
    func start() {
        let viewController = build()
        presenter?.pushViewController(viewController, animated: true)
    }
}
