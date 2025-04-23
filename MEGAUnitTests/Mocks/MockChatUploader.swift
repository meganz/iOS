@testable import MEGA

class MockChatUploader: ChatUploaderProtocol {
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
}
