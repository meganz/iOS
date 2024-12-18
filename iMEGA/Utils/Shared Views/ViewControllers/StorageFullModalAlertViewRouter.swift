import Foundation

struct StorageFullModalAlertViewRouter: StorageFullModalAlertViewRouting {
    private let requiredStorage: Int64
    private let limitedSpace: Int64

    init(
        requiredStorage: Int64 = Int64(1024 * 1024 * 1024),
        limitedSpace: Int64 = Int64(512 * 1024 * 1024)
    ) {
        self.requiredStorage = requiredStorage
        self.limitedSpace = limitedSpace
    }

    func startIfNeeded() {
        Task { @MainActor in
            let viewModel = StorageFullModalAlertViewModel(
                routing: self,
                requiredStorage: requiredStorage,
                limitedSpace: limitedSpace
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
