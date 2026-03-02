@testable import MEGA
import MEGADomain

final class MockChatUploader: ChatUploaderProtocol, @unchecked Sendable {
    var uploadImage_calledTimes: Int = 0
    var uploadFile_calledTimes: Int = 0
    
    var uploadImageCalled: (() -> Void)?
    
    func upload(image: UIImage, chatRoom: ChatRoomEntity) async {
        uploadImageCalled?()
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
