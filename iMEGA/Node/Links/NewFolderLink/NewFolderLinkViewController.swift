import FolderLink
import MEGAAppSDKRepo
import MEGADomain
import MEGAPreference
import MEGASdk
import SwiftUI
import UIKit

final class NewFolderLinkViewController: UIViewController {
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
    
    private func attachFolderLinkView() {
        navigationController?.navigationBar.isHidden = true
        let folderLinkViewController = UIHostingController(
            rootView: FolderLinkView(
                dependency: buildDependency(link: link),
                linkUnavailableContent: { reason in
                    FolderLinkUnavailableView(reason: reason)
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
    
    private func buildDependency(link: String) -> FolderLinkView<FolderLinkUnavailableView, FolderLinkMediaDiscoveryContentView>.Dependency {
        let sdk = MEGASdk.sharedFolderLink
        
        let searchResultMapper = FolderLinkSearchResultMapper(
            sdk: sdk,
            nodeValidationRepository: NodeValidationRepository.folderLink,
            nodeDataRepository: NodeDataRepository.newRepo,
            thumbnailRepository: ThumbnailRepository.folderLinkThumbnailRepository(),
            nodeIconRepository: NodeAssetsManager.shared
        )
        
        let sortOrderPreferenceUseCase = SortOrderPreferenceUseCase(
            preferenceUseCase: PreferenceUseCase.default,
            sortOrderPreferenceRepository: SortOrderPreferenceRepository.newRepo
        )
        
        let fileNodeOpener = FolderLinkFileNodeOpener(navigationController: navigationController)
        let nodeActionHandler = FolderLinkNodeActionHandler(navigationController: navigationController)
        return FolderLinkView.Dependency(
            link: link,
            folderLinkBuilder: MEGAFolderLinkBuilder(),
            searchResultMapper: searchResultMapper,
            sortOrderPreferenceUseCase: sortOrderPreferenceUseCase,
            fileNodeOpener: fileNodeOpener,
            nodeActionHandler: nodeActionHandler,
            mediaDiscoveryContent: {
                FolderLinkMediaDiscoveryContentView(viewModel: $0)
            },
            onClose: { [weak self] in
                self?.dismiss(animated: true)
            }
        )
    }
}
