import Foundation

struct StorageFullModalAlertViewRouter: StorageFullModalAlertViewRouting {
    private let requiredStorage: Int64

    init(requiredStorage: Int64 = Int64(100 * 1024 * 1024)) {
        self.requiredStorage = requiredStorage
    }

    func startIfNeeded() {
        Task { @MainActor in
            let viewModel = StorageFullModalAlertViewModel(
                routing: self,
                requiredStorage: requiredStorage
            )
            if await viewModel.shouldShowAlert() {
                start(viewModel: viewModel)
            }
        }
    }

    @MainActor
    private func start(viewModel: StorageFullModalAlertViewModel) {
        let controller = StorageFullModalAlertViewController()
        controller.storageViewModel = viewModel
        controller.modalPresentationStyle = .overFullScreen
        guard !UIApplication.mnz_visibleViewController().isKind(of: StorageFullModalAlertViewController.self) else {
            return
        }
        UIApplication.mnz_visibleViewController().present(controller, animated: true)
    }
}
