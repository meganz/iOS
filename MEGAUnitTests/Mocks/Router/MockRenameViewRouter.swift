@testable import MEGA

class MockRenameViewRouter: RenameViewRouting {
    var didFinishSuccessfullyCalled = false
    var didFinishWithErrorCalled = false
    
    func renamingFinishedSuccessfully() {
        didFinishSuccessfullyCalled = true
    }
    
    func renamingFinishedWithError() {
        didFinishWithErrorCalled = true
    }
}
