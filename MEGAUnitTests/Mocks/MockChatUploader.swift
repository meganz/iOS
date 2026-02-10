@testable import MEGA
import MEGADomain

final class MockChatUploader: ChatUploaderProtocol, @unchecked Sendable {
    var uploadImage_calledTimes: Int = 0
    var uploadFile_calledTimes: Int = 0
    
    var uploadImageCalled: (() -> Void)?
    
    func upload(image: UIImage, chatRoomId: UInt64) async {
        uploadImageCalled?()
    }
    
    func upload(
        filepath: String,
        appData: String,
        chatRoomId: UInt64,
        parentNode: MEGANode,
        isSourceTemporary: Bool,
        delegate: MEGAStartUploadTransferDelegate
    ) {
        uploadFile_calledTimes += 1
    }
    
    func upload(
        filepath: String,
        chatRoomId: UInt64,
        parentNode: MEGANode,
        uploadOptions: MEGADomain.UploadOptionsEntity,
        delegate: MEGAStartUploadTransferDelegate
    ) {
        uploadFile_calledTimes += 1
    }
}
