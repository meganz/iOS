import FileLink
import SwiftUI
import UIKit

/// Shell of the revamped file link screen: it is presented before the link is resolved, so the
/// skeleton is on screen while the public node is fetched.
final class NewFileLinkViewController: UIViewController {
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
        attachFileLinkView()
    }

    private func attachFileLinkView() {
        navigationController?.navigationBar.isHidden = true
        let fileLinkViewController = UIHostingController(
            rootView: FileLinkView(
                dependency: buildDependency(),
                linkUnavailableContent: { reason in
                    FileLinkUnavailableView(reason: reason)
                }
            )
        )
        addChild(fileLinkViewController)
        let fileLinkView: UIView = fileLinkViewController.view
        view.addSubview(fileLinkView)
        fileLinkView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            fileLinkView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            fileLinkView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            fileLinkView.topAnchor.constraint(equalTo: view.topAnchor),
            fileLinkView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        fileLinkViewController.didMove(toParent: self)
    }

    private func buildDependency() -> FileLinkView<FileLinkUnavailableView>.Dependency {
        let nodeProvider = FileLinkNodeProvider()
        // Read now rather than when the file is opened or shared: the photo browser clears it as it closes.
        let encryptedLink = MEGALinkManager.secondaryLinkURL?.absoluteString
        let fileNodeOpener = FileLinkNodeOpener(
            navigationController: navigationController,
            nodeProvider: nodeProvider,
            encryptedLink: encryptedLink
        )

        return FileLinkView.Dependency(
            link: link,
            encryptedLink: encryptedLink,
            fileLinkBuilder: MEGAFileLinkBuilder(),
            fileNodeOpener: fileNodeOpener,
            actionHandler: FileLinkActionHandler(
                navigationController: navigationController,
                nodeProvider: nodeProvider
            ),
            transferIndicatorToolbarFactory: TransferIndicatorBarItemConfigurator.toolbarFactory,
            nodeProvider: nodeProvider,
            onClose: { [weak self] in
                self?.close()
            }
        )
    }

    private func close() {
        MEGALinkManager.resetUtilsForLinksWithoutSession()
        MEGALinkManager.secondaryLinkURL = nil
        dismiss(animated: true)
    }
}
