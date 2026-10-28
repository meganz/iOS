import MEGAAppPresentation
import MEGAAppSDKRepo
import MEGADomain
import MEGAPreference
import MEGAShareLink
import MEGASwiftUI
import SwiftUI

struct GetLinkRouter: Routing {
    private weak var presenter: UIViewController?
    private let nodes: [MEGANode]
    private let featureFlagProvider: any FeatureFlagProviderProtocol
    private let remoteFeatureFlagUseCase: any RemoteFeatureFlagUseCaseProtocol
    private let isReachablePromptingIfNot: () -> Bool
    
    private var isShareLinkRevampEnabled: Bool {
        featureFlagProvider.isFeatureFlagEnabled(for: .shareLinkRevamp)
            && remoteFeatureFlagUseCase.isFeatureFlagEnabled(for: .iosShareLinkRevamp)
    }
    
    init(presenter: UIViewController,
         nodes: [MEGANode],
         featureFlagProvider: some FeatureFlagProviderProtocol = DIContainer.featureFlagProvider,
         remoteFeatureFlagUseCase: some RemoteFeatureFlagUseCaseProtocol = DIContainer.remoteFeatureFlagUseCase,
         isReachablePromptingIfNot: @escaping () -> Bool = { DIContainer.isReachablePromptingIfNot() }) {
        self.presenter = presenter
        self.nodes = nodes
        self.featureFlagProvider = featureFlagProvider
        self.remoteFeatureFlagUseCase = remoteFeatureFlagUseCase
        self.isReachablePromptingIfNot = isReachablePromptingIfNot
    }
    
    func build() -> UIViewController {
        let copyrightUseCase = CopyrightUseCase(
            shareUseCase: ShareUseCase(
                shareRepository: ShareRepository.newRepo,
                filesSearchRepository: FilesSearchRepository.newRepo,
                nodeRepository: NodeRepository.newRepo))
        let viewModel = EnforceCopyrightWarningViewModel(preferenceUseCase: PreferenceUseCase.default,
                                                         copyrightUseCase: copyrightUseCase)
        
        if isShareLinkRevampEnabled {
            let shareLinkView = ShareLinkView(nodes: nodes.toNodeEntities())
            return ShareLinkHostingController(
                rootView: EnforceCopyrightWarningView(viewModel: viewModel) { shareLinkView }
            )
        }
        
        let view = EnforceCopyrightWarningView(viewModel: viewModel) {
            GetLinkView(nodes: nodes)
                .ignoresSafeArea(edges: .bottom)
                .navigationBarHidden(true)
        }
        return UIHostingController(rootView: view)
    }
    
    func start() {
        if isShareLinkRevampEnabled, !isReachablePromptingIfNot() { return }
        presenter?.present(build(), animated: true)
    }
}
