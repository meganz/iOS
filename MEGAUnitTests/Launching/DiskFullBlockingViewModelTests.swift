import XCTest
@testable import MEGA

final class DiskFullBlockingViewModelTests: XCTestCase {
    func testAction_onViewLoaded_configView() {
        let mockDeviceModel = "iPod Touch"
        let sut = DiskFullBlockingViewModel(router: MockDiskFullBlockingViewRouter(), deviceModel: mockDeviceModel)
        sut.dispatch(.onViewLoaded)
        let storagePath = String(format: NSLocalizedString("Settings > General > %@ Storage", comment: ""), mockDeviceModel)
        let description = String(format: NSLocalizedString("Free up some space by deleting apps you no longer use or large video files in your gallery. You can manage your storage in %@", comment: ""), storagePath)
        let expectedBlockingModel = DiskFullBlockingModel(title: NSLocalizedString("The device does not have enough space for MEGA to run properly.", comment: ""),
                                                  description: description,
                                                  highlightedText: storagePath,
                                                  manageDiskSpaceTitle: NSLocalizedString("Manage", comment: ""),
                                                  headerImageName: "blockingDiskFull")
        test(viewModel: sut, action: .onViewLoaded, expectedCommands: [.configView(expectedBlockingModel)])
    }
    
    func testAction_manage() {
        let mockDeviceModel = ""
        let mockRouter = MockDiskFullBlockingViewRouter()
        let sut = DiskFullBlockingViewModel(router: mockRouter, deviceModel: mockDeviceModel)
        test(viewModel: sut, action: .manage, expectedCommands: [])
        XCTAssertEqual(mockRouter.manageDiskSpace_calledTimes, 1)
    }
}

final class MockDiskFullBlockingViewRouter: DiskFullBlockingViewRouting {
    var manageDiskSpace_calledTimes = 0
    
    func manageDiskSpace() {
        manageDiskSpace_calledTimes += 1
    }
}
