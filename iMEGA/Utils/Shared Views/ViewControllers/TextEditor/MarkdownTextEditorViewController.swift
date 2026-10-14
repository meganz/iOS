import MEGAAppPresentation
import MEGAAssets
import MEGADesignToken
import MEGAL10n
import MEGATextEditor
import SwiftUI
import UIKit

/// Shows a Markdown file as a preview or in the editor.
/// It owns the UIKit bars. The SwiftUI content lives in a child hosting controller.
final class MarkdownTextEditorViewController: UIViewController {
    private let viewModel: TextEditorViewModel
    let contentState = MarkdownTextEditorContentState()
    private lazy var hostingController = UIHostingController(rootView: MarkdownTextEditorContentView(state: contentState))

    init(viewModel: TextEditorViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = TokenColors.Background.page
        addContent()

        viewModel.invokeCommand = { [weak self] command in
            DispatchQueue.main.async {
                self?.executeCommand(command)
            }
        }

        viewModel.dispatch(.setUpView)
        registerForTraitChangesAffectingNavigationBar()
    }

    private func addContent() {
        addChild(hostingController)
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(hostingController.view)
        NSLayoutConstraint.activate([
            hostingController.view.topAnchor.constraint(equalTo: view.topAnchor),
            hostingController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        hostingController.didMove(toParent: self)
    }

    /// The iOS 26 navigation bar keeps its own appearance. It must be set again for a new colour appearance.
    private func registerForTraitChangesAffectingNavigationBar() {
        registerForTraitChanges(UITraitCollection.systemTraitsAffectingColorAppearance) { (viewController: MarkdownTextEditorViewController, _: UITraitCollection) in
            viewController.styleGlassNavigationBar()
        }
    }

    private func styleGlassNavigationBar() {
        if #available(iOS 26.0, *), let navigationBar = navigationController?.navigationBar {
            AppearanceManager.setupLiquidGlassNavigationBar(navigationBar)
        }
    }
}

// MARK: - U-R-MVVM ViewController ViewType
extension MarkdownTextEditorViewController: ViewType {
    func executeCommand(_ command: TextEditorViewModel.Command) {
        switch command {
        case .configView(let textEditorModel, let shallUpdateContent, let isInRubbishBin, let isBackupNode):
            configView(textEditorModel, shallUpdateContent: shallUpdateContent, isInRubbishBin: isInRubbishBin, isBackupNode: isBackupNode)
        case .setupNavbarItems(let navbarItemsModel):
            setupNavbarItems(navbarItemsModel)
        case .setupLoadViews:
            contentState.loadingProgress = nil
            contentState.screen = .loading
        case .updateProgressView(let percentage):
            contentState.loadingProgress = Double(percentage)
            contentState.screen = .loading
        case .editFile:
            editTapped()
        case .showDuplicateNameAlert(let model):
            showDuplicateNameAlert(model)
        case .showRenameAlert(let model):
            showRenameAlert(model)
        case .startLoading:
            SVProgressHUD.setDefaultMaskType(.clear)
            SVProgressHUD.show()
        case .stopLoading:
            SVProgressHUD.dismiss()
        case .showError(let error):
            SVProgressHUD.showError(withStatus: error)
        case .showDiscardChangeAlert:
            showDiscardChangeAlert()
        }
    }

    @objc func editAfterOpen() {
        viewModel.dispatch(.editAfterOpen)
    }

    private func configView(_ model: TextEditorModel, shallUpdateContent: Bool, isInRubbishBin: Bool, isBackupNode: Bool) {
        TextEditorBarItems.applyTitle(model.textFile.fileName, to: navigationItem, shouldEnableGlassEffect: false)
        contentState.fileName = model.textFile.fileName

        if shallUpdateContent {
            contentState.text = model.textFile.content
        }
        switch model.textEditorMode {
        case .view:
            contentState.screen = .preview
        case .edit, .create:
            contentState.showEditor()
        case .load:
            break
        }

        if model.textEditorMode == .view && !isInRubbishBin {
            toolbarItems = TextEditorBarItems.bottomBarItems(
                accessLevel: isBackupNode ? .read : model.accessLevel ?? .unknown,
                target: self
            )
            navigationController?.setToolbarHidden(false, animated: true)
        } else {
            toolbarItems = nil
            navigationController?.setToolbarHidden(true, animated: true)
        }

        styleGlassNavigationBar()
    }

    private func setupNavbarItems(_ model: TextEditorNavbarItemsModel) {
        switch model.textEditorMode {
        case .load:
            navigationItem.leftBarButtonItem = UIBarButtonItem(title: model.leftItem.title, style: .plain, target: self, action: #selector(closeTapped))
            navigationItem.rightBarButtonItems = nil
        case .view:
            navigationItem.leftBarButtonItem = UIBarButtonItem(title: model.leftItem.title, style: .plain, target: self, action: #selector(closeTapped))
            navigationItem.rightBarButtonItems = model.rightItem.map { rightItem in
                [
                    UIBarButtonItem(
                        image: rightItem.image ?? MEGAAssets.UIImage.moreNavigationBar,
                        style: .plain,
                        target: self,
                        action: #selector(moreTapped(button:))
                    )
                ]
            }
        case .edit, .create:
            navigationItem.leftBarButtonItem = UIBarButtonItem(title: model.leftItem.title, style: .plain, target: self, action: #selector(cancelTapped))
            let saveItem = UIBarButtonItem(title: model.rightItem?.title, style: .plain, target: self, action: #selector(saveTapped))
            saveItem.setTitleTextAttributes([.font: UIFont.preferredFont(style: .callout, weight: .bold)], for: .normal)
            navigationItem.rightBarButtonItems = [saveItem, makeModeItem()]
        }

        TransferIndicatorBarItemConfigurator.injectIfNeeded(into: self)
    }

    // MARK: - Mode menu

    private func makeModeItem() -> UIBarButtonItem {
        let item = UIBarButtonItem(image: MEGAAssets.UIImage.moreNavigationBar, style: .plain, target: nil, action: nil)
        item.accessibilityLabel = Strings.Localizable.more
        item.accessibilityValue = contentState.textEditorMode.title
        item.menu = UIMenu(options: .singleSelection, children: MarkdownTextEditorMode.allCases.map { makeModeAction($0, modeItem: item) })
        return item
    }

    private func makeModeAction(_ mode: MarkdownTextEditorMode, modeItem: UIBarButtonItem) -> UIAction {
        UIAction(title: mode.title, state: mode == contentState.textEditorMode ? .on : .off) { [weak self, weak modeItem] _ in
            self?.viewModel.dispatch(.selectMarkdownMode(mode))
            self?.contentState.textEditorMode = mode
            // The bar is not rebuilt after a menu choice, so the value is set here.
            modeItem?.accessibilityValue = mode.title
        }
    }

    // MARK: - Alerts

    private func showDuplicateNameAlert(_ model: TextEditorDuplicateNameAlertModel) {
        let alert = TextEditorFileNameAlerts.makeDuplicateNameAlert(
            model,
            onRename: { [weak self] in
                self?.viewModel.dispatch(.renameFile)
            },
            onReplace: { [weak self] in
                self?.viewModel.dispatch(.uploadFile)
            }
        )
        UIApplication.mnz_presentingViewController().present(alert, animated: true, completion: nil)
    }

    private func showRenameAlert(_ model: TextEditorRenameAlertModel) {
        let alert = TextEditorFileNameAlerts.makeRenameAlert(model) { [weak self] newName in
            guard let self, MEGAReachabilityManager.isReachableHUDIfNot() else { return }
            viewModel.dispatch(.renameFileTo(newInputName: newName))
            TextEditorBarItems.applyTitle(newName, to: navigationItem, shouldEnableGlassEffect: true)
        }
        UIApplication.mnz_presentingViewController().present(alert, animated: true, completion: nil)
    }

    private func showDiscardChangeAlert() {
        guard let barButton = navigationItem.leftBarButtonItem else { return }
        let alert = UIAlertController().discardChanges(fromBarButton: barButton) { [weak self] in
            self?.viewModel.dispatch(.cancel)
        }
        present(alert, animated: true, completion: nil)
    }

    // MARK: - Taps

    @objc private func closeTapped() {
        viewModel.dispatch(.dismissTextEditorVC)
    }

    @objc private func moreTapped(button: UIBarButtonItem) {
        viewModel.dispatch(.showActions(sender: button))
    }

    @objc private func cancelTapped() {
        // A bar button tap does not end editing, so the editor writes its waiting edits first.
        contentState.flushEditor()
        viewModel.dispatch(.cancelText(content: contentState.text))
    }

    @objc private func saveTapped() {
        contentState.flushEditor()
        viewModel.dispatch(.saveText(content: contentState.text))
    }
}

// MARK: - TextEditorBarItemTarget
extension MarkdownTextEditorViewController: TextEditorBarItemTarget {
    func downloadTapped() {
        viewModel.dispatch(.downloadToOffline)
    }

    func editTapped() {
        viewModel.dispatch(.editFile)
    }

    func exportFileTapped(button: UIBarButtonItem) {
        viewModel.dispatch(.exportFile(sender: button))
    }

    func importTapped() {
        viewModel.dispatch(.importNode)
    }
}
