import MEGADomain
import MEGAPresentation
import MEGASDKRepo
import SwiftUI

struct GetLinkRouter: Routing {
    private weak var presenter: UIViewController?
    private let nodes: [MEGANode]
    
    init(presenter: UIViewController,
         nodes: [MEGANode]) {
        self.presenter = presenter
        self.nodes = nodes
    }
    
    func build() -> UIViewController {
        let viewModel = EnforceCopyrightWarningViewModel(preferenceUseCase: PreferenceUseCase.default,
                                                         shareUseCase: ShareUseCase(repo: ShareRepository.newRepo))
        let view = EnforceCopyrightWarningView(viewModel: viewModel) {
            GetLinkView(nodes: nodes)
                .ignoresSafeArea(edges: .bottom)
        }
        return UIHostingController(rootView: view)
    }
    
    func start() {
        presenter?.present(build(), animated: true)
    }
}
