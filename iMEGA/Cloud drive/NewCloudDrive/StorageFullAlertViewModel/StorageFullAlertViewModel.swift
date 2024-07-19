protocol StorageFullAlertViewRouting {
    func showStorageAlertIfNeeded()
}

final class StorageFullAlertViewModel {
    private let router: any StorageFullAlertViewRouting
    
    init(router: some StorageFullAlertViewRouting) {
        self.router = router
    }
    
    func showStorageAlertIfNeeded() async {
        router.showStorageAlertIfNeeded()
    }
}

extension StorageFullModalAlertViewController: StorageFullAlertViewRouting {}
