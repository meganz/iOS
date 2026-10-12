import CloudDrive
import MEGADomain
import SwiftUI

@objc final class CreateTextFileAlertViewRouter: NSObject, CreateTextFileAlertViewRouting {

    private weak var baseViewController: UIViewController?
    private weak var presenter: UIViewController?

    private var parentHandle: HandleEntity?
    private let isMarkdownEditorEnabled: Bool

    init(presenter: UIViewController?, parentHandle: HandleEntity?, isMarkdownEditorEnabled: Bool) {
        self.presenter = presenter
        self.parentHandle = parentHandle
        self.isMarkdownEditorEnabled = isMarkdownEditorEnabled
    }

    @objc convenience init(presenter: UIViewController?, isMarkdownEditorEnabled: Bool) {
        self.init(presenter: presenter, parentHandle: nil, isMarkdownEditorEnabled: isMarkdownEditorEnabled)
    }

    func build() -> UIViewController {
        isMarkdownEditorEnabled ? makeNewTextFileDialog() : makeLegacyAlert()
    }

    private func makeLegacyAlert() -> UIViewController {
        let vm = CreateTextFileAlertViewModel(router: self)
        let vc = CreateTextFileAlertViewController(title: nil, message: nil, preferredStyle: .alert)
        vc.configView()
        vc.viewModel = vm
        baseViewController = vc
        return vc
    }

    private func makeNewTextFileDialog() -> UIViewController {
        let viewModel = NewTextFileDialogViewModel(
            // Callers do not keep the router. The dialog holds it until it closes.
            onCreate: { fileName in
                self.didTapCreate(fileName)
            },
            onCancel: {
                self.baseViewController?.dismiss(animated: true)
            }
        )
        let hostingController = UIHostingController(rootView: NewTextFileDialogView(viewModel: viewModel))
        hostingController.modalPresentationStyle = .overFullScreen
        hostingController.modalTransitionStyle = .crossDissolve
        hostingController.view.backgroundColor = .clear
        baseViewController = hostingController
        return hostingController
    }

    /// Returns false when the dialog stays open because there is no network.
    private func didTapCreate(_ fileName: String) -> Bool {
        guard MEGAReachabilityManager.isReachableHUDIfNot() else { return false }
        // The closed dialog may be freed before this runs, and it is the only owner of the router.
        baseViewController?.dismiss(animated: true) {
            self.createTextFile(fileName)
        }
        return true
    }

    @objc func start() {
        guard let presenter = presenter else { return }
        presenter.present(build(), animated: true, completion: nil)
    }

    func createTextFile(_ fileName: String) {
        let textFile = TextFile(fileName: fileName)
        guard let presenter = presenter else { return }
        TextEditorViewRouter(
            textFile: textFile,
            textEditorMode: .create,
            parentHandle: parentHandle,
            presenter: presenter,
            isMarkdownEditorEnabled: isMarkdownEditorEnabled
        ).start()
    }
}
