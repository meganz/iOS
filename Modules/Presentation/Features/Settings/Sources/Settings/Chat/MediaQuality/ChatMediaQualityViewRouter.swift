import ChatRepo
import MEGAAppPresentation
import MEGADomain
import MEGARepo
import SwiftUI
import UIKit

public final class ChatMediaQualityViewRouter: Routing {
    private weak var navigationController: UINavigationController?
    private weak var baseViewController: UIViewController?
    
    public init(navigationController: UINavigationController?) {
        self.navigationController = navigationController
    }
    
    public func build() -> UIViewController {
        let viewModel = ChatMediaQualityViewModel(
            defaultPreferenceUseCase: PreferenceUseCase(
                repository: PreferenceRepository.newRepo
            ),
            groupPreferenceUseCase: PreferenceUseCase(
                repository: PreferenceRepository(userDefaults: UserDefaults(suiteName: "group.mega.ios")!)
            )
        )
        let hostingVC = UIHostingController(
            rootView: ChatMediaQualityView(viewModel: viewModel)
        )
        baseViewController = hostingVC
        return hostingVC
    }
    
    public func start() {
        navigationController?.pushViewController(build(), animated: true)
    }
}
