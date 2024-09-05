@MainActor
protocol StorageFullAlertViewRouting {
    func showStorageAlertIfNeeded()
}

@MainActor
final class StorageFullAlertViewModel {
    private let router: any StorageFullAlertViewRouting
    
    init(router: some StorageFullAlertViewRouting) {
        self.router = router
    }
    
    func showStorageAlertIfNeeded() {
        router.showStorageAlertIfNeeded()
    }
}

extension StorageFullModalAlertViewController: StorageFullAlertViewRouting {}
