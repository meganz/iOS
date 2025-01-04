@testable import MEGA
import MEGADomain
import XCTest

final class PasteImagePreviewViewModelTests: XCTestCase {
    @MainActor
    private func makeSUT(chatRoom: ChatRoomEntity = ChatRoomEntity()) -> (
        sut: PasteImagePreviewViewModel,
        mockRouter: MockPasteImagePreviewRouter,
        mockChatUploader: MockChatUploader
    ) {
        let mockRouter = MockPasteImagePreviewRouter()
        let mockChatUploader = MockChatUploader()
        let sut = PasteImagePreviewViewModel(
            router: mockRouter,
            chatRoom: chatRoom,
            chatUploader: mockChatUploader
        )
        return (sut, mockRouter, mockChatUploader)
    }

    @MainActor
    func testDispatch_didClickCancel_shouldDismissRouter() {
        let (sut, mockRouter, _) = makeSUT()
        sut.dispatch(.didClickCancel)
        XCTAssertTrue(mockRouter.dismiss_calledTimes == 1)
    }

    @MainActor
    func testDispatch_didClickSend_withImageInPasteboard_shouldUploadImage() {
        let (sut, mockRouter, mockChatUploader) = makeSUT(chatRoom: ChatRoomEntity())
        UIPasteboard.general.image = UIImage()
        sut.dispatch(.didClickSend)
        XCTAssertTrue(mockRouter.dismiss_calledTimes == 1)
        XCTAssertTrue(mockChatUploader.uploadImage_calledTimes == 1)
    }

    @MainActor
    func testDispatch_didClickSend_withNoImageInPasteboard_shouldNotUploadImage() {
        let (sut, mockRouter, mockChatUploader) = makeSUT(chatRoom: ChatRoomEntity())
        UIPasteboard.general.image = nil
        sut.dispatch(.didClickSend)
        XCTAssertTrue(mockRouter.dismiss_calledTimes == 1)
        XCTAssertFalse(mockChatUploader.uploadImage_calledTimes == 1)
    }
}
