import MEGADomain
import MEGAPermissions

@MainActor
protocol SaveToPhotosCoordinatorProtocol: AnyObject {
    func saveToPhotos(nodes: [NodeEntity], onComplete: (() -> Void)?)
    func saveToPhotos(fileLink: FileLinkEntity, onComplete: (() -> Void)?)
    func saveToPhotosChatNode(handle: HandleEntity, messageId: HandleEntity, chatId: HandleEntity, onComplete: (() -> Void)?)
    func showPhotoPermissionAlert()
    func showProgress()
    func showError(_ error: any Error)
}

extension SaveToPhotosCoordinatorProtocol {
    func saveToPhotos(nodes: [NodeEntity]) {
        saveToPhotos(nodes: nodes, onComplete: nil)
    }
    
    func saveToPhotos(fileLink: FileLinkEntity) {
        saveToPhotos(fileLink: fileLink, onComplete: nil)
    }
    
    func saveToPhotosChatNode(handle: HandleEntity, messageId: HandleEntity, chatId: HandleEntity) {
        saveToPhotosChatNode(handle: handle, messageId: messageId, chatId: chatId, onComplete: nil)
    }
}

@MainActor
final class SaveToPhotosViewModel {
    private weak var coordinator: (any SaveToPhotosCoordinatorProtocol)?
    private let overDiskQuotaChecker: any OverDiskQuotaChecking
    private let devicePermissionsHandling: any DevicePermissionsHandling
    private let saveMediaToPhotosUseCase: any SaveMediaToPhotosUseCaseProtocol
    
    init(
        coordinator: some SaveToPhotosCoordinatorProtocol,
        overDiskQuotaChecker: some OverDiskQuotaChecking,
        devicePermissionsHandling: some DevicePermissionsHandling,
        saveMediaToPhotosUseCase: any SaveMediaToPhotosUseCaseProtocol
    ) {
        self.coordinator = coordinator
        self.overDiskQuotaChecker = overDiskQuotaChecker
        self.devicePermissionsHandling = devicePermissionsHandling
        self.saveMediaToPhotosUseCase = saveMediaToPhotosUseCase
    }
    
    func saveToPhotos(nodes: [NodeEntity]) async {
        await performSaveToPhotos { [saveMediaToPhotosUseCase] in
            try await saveMediaToPhotosUseCase.saveToPhotos(nodes: nodes)
        }
    }
    
    func saveToPhotos(fileLink: FileLinkEntity) async {
        await performSaveToPhotos { [saveMediaToPhotosUseCase] in
            try await saveMediaToPhotosUseCase.saveToPhotos(fileLink: fileLink)
        }
    }
    
    func saveToPhotosChatNode(handle: HandleEntity, messageId: HandleEntity, chatId: HandleEntity) async {
        await performSaveToPhotos { [saveMediaToPhotosUseCase] in
            try await saveMediaToPhotosUseCase.saveToPhotosChatNode(
                handle: handle, messageId: messageId, chatId: chatId)
        }
    }
    
    private func performSaveToPhotos(_ saveOperation: @escaping () async throws -> Void) async {
        guard !overDiskQuotaChecker.showOverDiskQuotaIfNeeded() else { return }
        guard await devicePermissionsHandling.requestPhotoLibraryAccessPermissions() else {
            coordinator?.showPhotoPermissionAlert()
            MEGALogError("[\(type(of: self))] PhotoLibraryAccessPermissions not granted")
            return
        }
        coordinator?.showProgress()
        
        do {
            try await saveOperation()
        } catch {
            guard let errorEntity = error as? SaveMediaToPhotosErrorEntity,
                  errorEntity != .cancelled  else {
                return
            }
            MEGALogError("[\(type(of: self))] failed to save photos: \(error)")
            coordinator?.showError(error)
        }
    }
}
