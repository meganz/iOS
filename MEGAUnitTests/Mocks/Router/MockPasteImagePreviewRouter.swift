@testable import MEGA

final class MockPasteImagePreviewRouter: PasteImagePreviewRouting {
    var dismiss_calledTimes = 0
    
    func dismiss() {
        dismiss_calledTimes += 1
    }
}
