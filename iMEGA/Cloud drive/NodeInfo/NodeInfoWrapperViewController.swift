import MEGADesignToken
import MEGAL10n
import MEGAUIKit
import UIKit

/// A view controller that acts as a wrapper for `NodeInfoViewController`
/// to ensure that the table view content does not spill over the safe area.
///
/// This class is responsible for embedding the `NodeInfoViewController`'s view
/// within its own view hierarchy and managing its presentation and dismissal logic.
final class NodeInfoWrapperViewController: UIViewController {
    private let nodeInfoViewController: NodeInfoViewController
    var snackBarContainer: UIView?

    init(with nodeInfoViewController: NodeInfoViewController) {
        self.nodeInfoViewController = nodeInfoViewController
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        configureUI()
        addNodeInfoAsChild()
        configurePresentAndDismiss()
        configureShowSavedDescriptionState()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        configureSnackBarPresenter()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        removeSnackBarPresenter()
    }

    private func addNodeInfoAsChild() {
        addChild(nodeInfoViewController)

        guard let subview = nodeInfoViewController.view else { return }
        subview.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(subview)

        let safeAreaLayoutGuide = view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            subview.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor),
            subview.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor),
            subview.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor),
            subview.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor)
        ])

        nodeInfoViewController.didMove(toParent: self)
    }

    private func configureUI() {
        view.backgroundColor = TokenColors.Background.page
        title = Strings.Localizable.info
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: Strings.Localizable.close,
            style: .plain,
            target: self,
            action: #selector(dismissScreen)
        )
    }

    @objc private func dismissScreen() {
        if nodeInfoViewController.hasPendingNodeDescriptionChanges?() == true,
           let saveNodeDescriptionChanges = nodeInfoViewController.saveNodeDescriptionChanges {
            showNodeDescriptionAlert(saveDescription: saveNodeDescriptionChanges) {
                self.dismissView()
            }
        } else {
            dismissView()
        }
    }

    private func configurePresentAndDismiss() {
        nodeInfoViewController.presentViewController = { [weak self] viewControllerToPresent in
            guard let self else { return }
            present(viewControllerToPresent, animated: true)
        }

        nodeInfoViewController.dismissViewController = { [weak self] completion in
            guard let self else { return }
            dismiss(animated: true, completion: completion)
        }
    }

    private func configureShowSavedDescriptionState() {
        nodeInfoViewController.showSavedDescriptionState = { [weak self] savedState in
            guard let self else { return }
            showSnackBar(with: savedState.localizedString)
        }
    }

    private func showNodeDescriptionAlert(
        saveDescription: @escaping () async -> NodeDescriptionCellControllerModel.SavedState?,
        close: @escaping () -> Void
    ) {
        let alert = UIAlertController(
            title: Strings.Localizable.CloudDrive.NodeInfo.NodeDescription.ClosePopup.title,
            message: Strings.Localizable.CloudDrive.NodeInfo.NodeDescription.ClosePopup.message,
            preferredStyle: .alert
        )

        alert.addAction(
            title: Strings.Localizable.CloudDrive.NodeInfo.NodeDescription.ClosePopup.discardButtonTitle,
            handler: close
        )

        alert.addAction(
            title: Strings.Localizable.CloudDrive.NodeInfo.NodeDescription.ClosePopup.keepEditingButtonTitle
        )

        alert.addAction(
            title: Strings.Localizable.CloudDrive.NodeInfo.NodeDescription.ClosePopup.saveAndCloseButtonTitle,
            style: .cancel,
            handler: { [weak self] in
                Task { @MainActor [weak self] in
                    guard let savedState = await saveDescription(), let self else {
                        close()
                        return
                    }

                    switch savedState {
                    case .added, .removed, .updated:
                        close()
                    case .error:
                        showSnackBar(with: savedState.localizedString)
                    }
                }
            }
        )

        present(alert, animated: true)
    }
}
