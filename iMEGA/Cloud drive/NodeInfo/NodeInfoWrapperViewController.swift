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
            showNodeDescriptionAlert(saveDescription: saveNodeDescriptionChanges) { [weak self] completion in
                guard let self, let completion else {
                    self?.dismissView()
                    return
                }
                
                dismiss(animated: true) { completion() }
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
            self.showSnackBar(message: savedState.localizedString)
        }
    }

    private func showNodeDescriptionAlert(
        saveDescription: @escaping () async -> NodeDescriptionCellControllerModel.SavedState?,
        close: @escaping ((() -> Void)?) -> Void
    ) {
        let alert = UIAlertController(
            title: Strings.Localizable.CloudDrive.NodeInfo.NodeDescription.ClosePopup.title,
            message: Strings.Localizable.CloudDrive.NodeInfo.NodeDescription.ClosePopup.message,
            preferredStyle: .alert
        )

        alert.addAction(
            title: Strings.Localizable.CloudDrive.NodeInfo.NodeDescription.ClosePopup.discardButtonTitle,
            handler: { close(nil) }
        )

        alert.addAction(
            title: Strings.Localizable.CloudDrive.NodeInfo.NodeDescription.ClosePopup.keepEditingButtonTitle
        )

        alert.addAction(
            title: Strings.Localizable.CloudDrive.NodeInfo.NodeDescription.ClosePopup.saveAndCloseButtonTitle,
            style: .cancel,
            handler: {
                Task { @MainActor in
                    guard let savedState = await saveDescription() else {
                        close(nil)
                        return
                    }

                    let completion = {
                        UIApplication.mnz_visibleViewController().showSnackBar(message: savedState.localizedString)
                    }

                    switch savedState {
                    case .added, .removed, .updated:
                        close(completion)
                    case .error:
                        completion()
                    }
                }
            }
        )

        present(alert, animated: true)
    }
}
