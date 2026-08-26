import SwiftUI
import Transfer
import UIKit

/// Hosts `ImportAlbumView` as a child rather than presenting its `UIHostingController` directly.
final class AlbumLinkViewController: UIViewController {
    private let viewModel: ImportAlbumViewModel

    init(viewModel: ImportAlbumViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // The screen draws its own bar through the SwiftUI `NavigationStack`; the enclosing
        // navigation controller is there for the toolbar hosting, not to show a second bar.
        navigationController?.navigationBar.isHidden = true

        // The hosted view is no longer the presented view controller, so SwiftUI's `presentationMode`
        // cannot close the screen -- the dismissal has to come back through here.
        let hostingController = UIHostingController(
            rootView: ImportAlbumView(
                viewModel: self.viewModel,
                transferIndicatorToolbarFactory: TransferIndicatorBarItemConfigurator.toolbarFactory,
                invokeDismiss: { [weak self] in
                    self?.dismiss(animated: true)
                }
            )
        )

        addChild(hostingController)
        let hostedView: UIView = hostingController.view
        hostedView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(hostedView)
        NSLayoutConstraint.activate([
            hostedView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hostedView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            hostedView.topAnchor.constraint(equalTo: view.topAnchor),
            hostedView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        hostingController.didMove(toParent: self)
    }
}
