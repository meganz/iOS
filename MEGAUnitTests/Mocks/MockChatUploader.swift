@testable import MEGA

class MockChatUploader: ChatUploaderProtocol {
    var uploadImage_calledTimes: Int = 0
    var uploadFile_calledTimes: Int = 0
    
    func upload(image: UIImage, chatRoomId: UInt64) {
        uploadImage_calledTimes += 1
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
}
