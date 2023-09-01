import Foundation
@testable import MEGA

class MockTransferWidgetResponder: TransferWidgetResponderProtocol {

    var bringProgressToFrontKeyWindowIfNeededCalled: Int = 0
    var setProgressViewInKeyWindowCalled: Int = 0
    var updateProgressViewCalled: Int = 0
    var showWidgetIfNeededCalled: Int = 0
    
    func bringProgressToFrontKeyWindowIfNeeded() {
        bringProgressToFrontKeyWindowIfNeededCalled += 1
    }
    
    func setProgressViewInKeyWindow() {
        setProgressViewInKeyWindowCalled += 1
    }
    
    func updateProgressView(bottomConstant: CGFloat) {
        updateProgressViewCalled += 1
    }
    
    func showWidgetIfNeeded() {
        showWidgetIfNeededCalled += 1
    }
}
