import MEGADomain
import MEGAL10n
import MEGASwift
import VisionKit

private final class MegaVNDocCameraViewControllerDeallocObserver: Sendable {
    let action: @Sendable () -> Void
    init(_ action: @escaping @Sendable () -> Void) { self.action = action }
    deinit { action() }
}

extension VNDocumentCameraViewController {
    private static var megaDocCameraViewControllerDeallocObserverKey: UInt8 = 0
    func onDeinit(_ action: @escaping @Sendable () -> Void) {
        objc_setAssociatedObject(self, &VNDocumentCameraViewController.megaDocCameraViewControllerDeallocObserverKey, MegaVNDocCameraViewControllerDeallocObserver(action), .OBJC_ASSOCIATION_RETAIN)
    }
}

struct ScanDocumentViewRouter: Sendable {
    private let presenter: UIViewController
    private let parent: NodeEntity

    init(presenter: UIViewController, parent: NodeEntity) {
        self.presenter = presenter
        self.parent = parent
    }

    func start() async {
        guard let scanDocumentViewControllerDelegate = await presentDocumentScanner() else { return }
        guard let docs = await scanDocumentViewControllerDelegate.scannedImages() else { return }
        await presentDocScannerSaveSettingTableViewController(docs: docs)
    }

    // MARK: - Private methods

    @MainActor
    private func presentDocumentScanner() -> ScanDocumentViewControllerDelegate? {
        guard VNDocumentCameraViewController.isSupported else {
            SVProgressHUD.showError(withStatus: Strings.Localizable.documentScanningIsNotAvailable)
            return nil
        }

        let scanVC = VNDocumentCameraViewController()
        let scanDocumentViewControllerDelegate = ScanDocumentViewControllerDelegate()
        scanVC.delegate = scanDocumentViewControllerDelegate
        scanVC.onDeinit { [weak scanDocumentViewControllerDelegate] in
            scanDocumentViewControllerDelegate?.cancelContinuation()
        }
        presenter.present(scanVC, animated: true)
        return scanDocumentViewControllerDelegate
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
    
    deinit {
        continuation?.resume(with: .success(nil))
    }
    
    func cancelContinuation() {
        continuation?.resume(with: .success(nil))
        $continuation.mutate { $0 = nil }
    }

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
            self.$continuation.mutate { $0 = nil }
        }
    }

    func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
        controller.dismiss(animated: true) {
            self.continuation?.resume(with: .success(nil))
            self.$continuation.mutate { $0 = nil }
        }
    }

    func documentCameraViewController(
        _ controller: VNDocumentCameraViewController, didFailWithError error: any Error
    ) {
        controller.dismiss(animated: true) {
            self.continuation?.resume(with: .success(nil))
            self.$continuation.mutate { $0 = nil }
        }
    }
}
