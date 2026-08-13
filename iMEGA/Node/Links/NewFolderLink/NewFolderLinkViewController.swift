import Combine
import FolderLink
import MEGAAppPresentation
import MEGAAppSDKRepo
import MEGADomain
import MEGAPreference
import MEGASdk
import SwiftUI
import UIKit

final class NewFolderLinkViewController: UIViewController, AudioPlayerPresenterProtocol {
    func updateContentView(_ height: CGFloat) {}
    
    func hasUpdatedContentView() -> Bool { true }
    
    private let link: String
    
    init(link: String) {
        self.link = link
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        attachFolderLinkView()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        guard !isAudioPlayerRevampEnabled else { return }
        AudioPlayerManager.shared.updateMiniPlayerPresenter(self)
    }
    
    private var isAudioPlayerRevampEnabled: Bool {
        DIContainer.featureFlagProvider.isFeatureFlagEnabled(for: .audioPlayerRevamp)
    }

    private func attachFolderLinkView() {
        navigationController?.navigationBar.isHidden = true
        // The local flag is read here, at the composition root, and nowhere else.
        let isLinkRevampEnabled = MEGALinkManager.isLinkRevampEnabled
        let isAudioPlayerRevampEnabled = isAudioPlayerRevampEnabled
        let folderLinkViewController = UIHostingController(
            rootView: FolderLinkView(
                dependency: buildDependency(link: link, isLinkRevampEnabled: isLinkRevampEnabled),
                linkUnavailableContent: { reason in
                    FolderLinkUnavailableView(reason: reason, isLinkRevampEnabled: isLinkRevampEnabled)
                },
                miniPlayerContent: { [weak self] viewModel in
                    FolderLinkMiniPlayerView(
                        viewModel: viewModel,
                        isAudioPlayerRevampEnabled: isAudioPlayerRevampEnabled,
                        presenter: { self }
                    )
                }
            )
        )
        addChild(folderLinkViewController)
        let folderLinkView: UIView = folderLinkViewController.view
        view.addSubview(folderLinkView)
        folderLinkView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            folderLinkView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            folderLinkView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            folderLinkView.topAnchor.constraint(equalTo: view.topAnchor),
            folderLinkView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        folderLinkViewController.didMove(toParent: self)
    }
    
    private func buildDependency<MiniPlayer>(link: String, isLinkRevampEnabled: Bool) -> FolderLinkView<FolderLinkUnavailableView, FolderLinkMediaDiscoveryContentView, MiniPlayer>.Dependency {
        let sortOrderPreferenceUseCase = SortOrderPreferenceUseCase(
            preferenceUseCase: PreferenceUseCase.default,
            sortOrderPreferenceRepository: SortOrderPreferenceRepository.newRepo
        )
        
        let fileNodeOpener = FolderLinkFileNodeOpener(navigationController: navigationController)
        let nodeActionHandler = FolderLinkNodeActionHandler(
            navigationController: navigationController,
            isLinkRevampEnabled: isLinkRevampEnabled
        )
        
        return FolderLinkView.Dependency(
            link: link,
            folderLinkBuilder: MEGAFolderLinkBuilder(),
            folderLinkLogoutPolicy: FolderLinkLogoutPolicy(),
            searchResultsProvidingBuilder: FolderLinkSearchResultsProvidingBuilder(),
            sortOrderPreferenceUseCase: sortOrderPreferenceUseCase,
            fileNodeOpener: fileNodeOpener,
            nodeActionHandler: nodeActionHandler,
            transferIndicatorToolbarFactory: TransferIndicatorBarItemConfigurator.toolbarFactory,
            isLinkRevampEnabled: isLinkRevampEnabled,
            mediaDiscoveryContent: {
                FolderLinkMediaDiscoveryContentView(viewModel: $0)
            },
            onClose: { [weak self] in
                self?.dismiss(animated: true)
            }
        )
    }
}
