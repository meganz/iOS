import Foundation
@testable import MEGA

class MockTransferWidgetResponder: TransferWidgetResponderProtocol {
    
    var bringProgressToFrontKeyWindowIfNeededCalled: Int = 0
    
    func bringProgressToFrontKeyWindowIfNeeded() {
        bringProgressToFrontKeyWindowIfNeededCalled += 1
    }
}
