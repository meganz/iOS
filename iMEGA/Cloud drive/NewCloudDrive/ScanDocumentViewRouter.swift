import MEGADomain
import MEGAL10n
import MEGASwift
import VisionKit

struct ScanDocumentViewRouter: Sendable {
    private let presenter: UIViewController
    private let parent: NodeEntity
    private let scanDocumentViewControllerDelegate = ScanDocumentViewControllerDelegate()

    init(presenter: UIViewController, parent: NodeEntity) {
        self.presenter = presenter
        self.parent = parent
    }

    func start() async {
        await presentDocumentScanner()
        guard let docs = await scanDocumentViewControllerDelegate.scannedImages() else { return }
        await presentDocScannerSaveSettingTableViewController(docs: docs)
    }

    // MARK: - Private methods

    @MainActor
    private func presentDocumentScanner() {
        guard VNDocumentCameraViewController.isSupported else {
            SVProgressHUD.showError(withStatus: Strings.Localizable.documentScanningIsNotAvailable)
            return
        }

        let scanVC = VNDocumentCameraViewController()
        scanVC.delegate = scanDocumentViewControllerDelegate
        presenter.present(scanVC, animated: true)
    }

    @MainActor
    private func presentDocScannerSaveSettingTableViewController(docs: [UIImage]) {
        let storyboard = UIStoryboard(name: "Cloud", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "DocScannerSaveSettingTableViewController")
        guard let vc = vc as? DocScannerSaveSettingTableViewController else { return }

        vc.parentNodeEntity = parent
        vc.docs = docs

        let navigationVC = MEGANavigationController(rootViewController: vc)
        navigationVC.addLeftDismissButton(withText: Strings.Localizable.cancel)
        navigationVC.modalPresentationStyle = .fullScreen
        presenter.present(navigationVC, animated: true)
    }
}

private final class ScanDocumentViewControllerDelegate: NSObject, @unchecked Sendable, VNDocumentCameraViewControllerDelegate {
    @Atomic private var continuation: CheckedContinuation<[UIImage]?, Never>?

    func scannedImages() async -> [UIImage]? {
        await withCheckedContinuation { continuation in
            self.$continuation.mutate { $0 = continuation }
        }
    }

    func documentCameraViewController(
        _ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan
    ) {
        controller.dismiss(animated: true) {
            let docs = (0..<scan.pageCount).map(scan.imageOfPage)
            self.continuation?.resume(with: .success(docs))
        }
    }

    func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
        controller.dismiss(animated: true) {
            self.continuation?.resume(with: .success(nil))
        }
    }

    func documentCameraViewController(
        _ controller: VNDocumentCameraViewController, didFailWithError error: any Error
    ) {
        controller.dismiss(animated: true) {
            self.continuation?.resume(with: .success(nil))
        }
    }
}
