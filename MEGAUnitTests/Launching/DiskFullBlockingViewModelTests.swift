@testable import MEGA
import MEGAL10n
import XCTest

final class DiskFullBlockingViewModelTests: XCTestCase {
    @MainActor
    func testAction_onViewLoaded_configView() {
        let mockDeviceModel = "iPod Touch"
        let sut = DiskFullBlockingViewModel(router: MockDiskFullBlockingViewRouter(), deviceModel: mockDeviceModel)
        sut.dispatch(.onViewLoaded)
        let storagePath = Strings.Localizable.settingsGeneralStorage(mockDeviceModel)
        let description = Strings.Localizable.FreeUpSomeSpaceByDeletingAppsYouNoLongerUseOrLargeVideoFilesInYourGallery.youCanManageYourStorageIn(storagePath)
        let expectedBlockingModel = DiskFullBlockingModel(title: Strings.Localizable.theDeviceDoesNotHaveEnoughSpaceForMEGAToRunProperly,
                                                  description: description,
                                                  highlightedText: storagePath,
                                                  manageDiskSpaceTitle: Strings.Localizable.close,
                                                  headerImage: UIImage.blockingDiskFull)
        test(viewModel: sut, action: .onViewLoaded, expectedCommands: [.configView(expectedBlockingModel)])
    }
    
    @MainActor
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
