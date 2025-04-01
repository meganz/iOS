import MEGAAppPresentation
import MEGADomain
import MEGASDKRepo
import MEGASwiftUI
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
        let copyrightUseCase = CopyrightUseCase(
            shareUseCase: ShareUseCase(
                shareRepository: ShareRepository.newRepo,
                filesSearchRepository: FilesSearchRepository.newRepo,
                nodeRepository: NodeRepository.newRepo))
        let viewModel = EnforceCopyrightWarningViewModel(preferenceUseCase: PreferenceUseCase.default,
                                                         copyrightUseCase: copyrightUseCase)
        
        let view = EnforceCopyrightWarningView(viewModel: viewModel) {
            GetLinkView(nodes: nodes)
                .ignoresSafeArea(edges: .bottom)
                .navigationBarHidden(true)
        }
        return UIHostingController(rootView: view)
    }
    
    func start() {
        presenter?.present(build(), animated: true)
    }
}
