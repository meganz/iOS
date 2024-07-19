@testable import MEGA
import MEGAPresentationMock
import MEGASDKRepoMock
import XCTest

struct MockStorageFullAlertViewRouting: StorageFullAlertViewRouting {
    
    let showStorageAlertIfNeededRecorder = FuncCallRecorder<Void, Void>()
    func showStorageAlertIfNeeded() {
        showStorageAlertIfNeededRecorder.call()
    }
}

final class StorageFullAlertViewModelTests: XCTestCase {
    class Harness {
        let sut: StorageFullAlertViewModel
        let router: MockStorageFullAlertViewRouting
        
        init() {
            router = .init()
            sut = .init(router: router)
        }
    }
    
    func testShowStorageAlertIfNeeded() async {
        let harness = Harness()
        await harness.sut.showStorageAlertIfNeeded()
        XCTAssertEqual(harness.router.showStorageAlertIfNeededRecorder.callCount, 1)
    }
}
