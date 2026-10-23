import Combine
import FolderLink
import MEGAAppPresentation
import MEGAAppSDKRepo
import MEGAAudioPlayer
import MEGADomain
import MEGAPreference
import MEGASdk
import SwiftUI
import UIKit

final class NewFolderLinkViewController: UIViewController, AudioPlayerPresenterProtocol {
    func updateContentView(_ height: CGFloat) {}
    
    func hasUpdatedContentView() -> Bool { true }
    
    private let link: String
    /// Kept apart from `link` and passed through untouched: `link` is what the SDK logs in to, while
    /// this is the form the user was given, and the only form safe to store.
    private let receivedLink: String
    
    private var hasStoppedAudioOnLeavingFolderLink = false

    init(link: String, receivedLink: String) {
        self.link = link
        self.receivedLink = receivedLink
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
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        // Closed by the user or replaced by another link opening, not just covered
        guard !hasStoppedAudioOnLeavingFolderLink, isBeingRemoved else { return }
        stopAudioPlaybackIfLoggedOut()
    }

    /// Whether this screen is going away for good: it is presented inside a navigation controller and an
    /// ads container, so it is the container being dismissed, from its close button or by another link.
    private var isBeingRemoved: Bool {
        sequence(first: self as UIViewController, next: \.parent).contains { $0.isBeingDismissed }
    }

    private var isAudioPlayerRevampEnabled: Bool {
        DIContainer.featureFlagProvider.isFeatureFlagEnabled(for: .audioPlayerRevamp) || DIContainer.remoteFeatureFlagUseCase.isFeatureFlagEnabled(for: .iosAudioPlayerRevamp)
    }

    /// Logged out, this screen's mini player is the only one there is: playback started here can't
    /// outlive it, or nothing would be left to control it. Runs from both the close button and
    /// `viewDidDisappear`, so it stops the audio only once.
    private func stopAudioPlaybackIfLoggedOut() {
        guard !hasStoppedAudioOnLeavingFolderLink,
              isAudioPlayerRevampEnabled,
              !AccountUseCase(repository: AccountRepository.newRepo).isLoggedIn() else { return }
        hasStoppedAudioOnLeavingFolderLink = true
        MEGAAudioPlayerSession.stop()
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
            linkResolutionReporter: ViewedLinksRecorder.shared,
            receivedLink: receivedLink,
            mediaDiscoveryContent: {
                FolderLinkMediaDiscoveryContentView(viewModel: $0)
            },
            onClose: { [weak self] in
                self?.stopAudioPlaybackIfLoggedOut()
                self?.dismiss(animated: true)
            }
        )
    }
}
