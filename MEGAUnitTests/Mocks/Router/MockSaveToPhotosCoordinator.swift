@testable import MEGA
import MEGADomain
import MEGATest

class MockSaveToPhotosCoordinator: MockObject<MockSaveToPhotosCoordinator.Actions>, SaveToPhotosCoordinatorProtocol {
    enum Actions {
        case saveToPhotos(nodes: [NodeEntity])
        case saveToPhotosFileLink(fileLink: FileLinkEntity)
        case saveToPhotosChatNode(handle: HandleEntity, messageId: HandleEntity, chatId: HandleEntity)
        case showPhotoPermissionAlert
        case showProgress
        case showError(any Error)
    }
    
    func saveToPhotos(nodes: [NodeEntity], onComplete: (() -> Void)? = nil) {
        actions.append(.saveToPhotos(nodes: nodes))
        onComplete?()
    }
    
    func saveToPhotos(fileLink: FileLinkEntity, onComplete: (() -> Void)? = nil) {
        actions.append(.saveToPhotosFileLink(fileLink: fileLink))
        onComplete?()
    }
    
    func saveToPhotosChatNode(handle: HandleEntity, messageId: HandleEntity, chatId: HandleEntity, onComplete: (() -> Void)? = nil) {
        actions.append(.saveToPhotosChatNode(handle: handle, messageId: messageId, chatId: chatId))
        onComplete?()
    }
    
    func showPhotoPermissionAlert() {
        actions.append(.showPhotoPermissionAlert)
    }
    
    func showProgress() {
        actions.append(.showProgress)
    }
    
    func showError(_ error: any Error) {
        actions.append(.showError(error))
    }
}

extension MockSaveToPhotosCoordinator.Actions: Equatable {
    static func == (lhs: MockSaveToPhotosCoordinator.Actions, rhs: MockSaveToPhotosCoordinator.Actions) -> Bool {
        switch (lhs, rhs) {
        case (.saveToPhotos(let lhsNodes), .saveToPhotos(let rhsNodes)):
            lhsNodes == rhsNodes
        case (.saveToPhotosFileLink(let lhsFileLink), .saveToPhotosFileLink(let rhsFileLink)):
            lhsFileLink.linkURL == rhsFileLink.linkURL
        case (.saveToPhotosChatNode(let lhsHandle, let lhsMessageId, let lhsChatId),
              .saveToPhotosChatNode(let rhsHandle, let rhsMessageId, let rhsChatId)):
            lhsHandle == rhsHandle && lhsMessageId == rhsMessageId && lhsChatId == rhsChatId
        case (.showPhotoPermissionAlert, .showPhotoPermissionAlert):
            true
        case (.showProgress, .showProgress):
            true
        case (.showError(let lhsError), .showError(let rhsError)):
            lhsError.localizedDescription == rhsError.localizedDescription
        default:
            false
        }
    }
}
