import MEGADesignToken
import MEGAL10n
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
            action: #selector(dismissView)
        )
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
}
