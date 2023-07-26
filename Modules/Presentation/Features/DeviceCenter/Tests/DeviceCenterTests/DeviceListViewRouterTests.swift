@testable import DeviceCenter
import MEGADomain
import MEGADomainMock
import SwiftUI
import XCTest

final class DeviceListViewRouterTests: XCTestCase {
    
    func testBuild_rendersCorrectViewController() throws {
        let (sut, _) = try makeSUT()
        
        let resultViewController = sut.build()
        
        XCTAssert(resultViewController is UIHostingController<DeviceListView>)
    }
    
    func testStart_pushCorrectViewController() throws {
        let (sut, mockPresenter) = try makeSUT()
        
        sut.start()
        
        let viewController = try XCTUnwrap(mockPresenter.viewControllers.first)
        
        XCTAssertTrue(viewController is UIHostingController<DeviceListView>)
    }
    
    // MARK: - Helpers
    
    private func makeSUT() throws -> (sut: DeviceListViewRouter, mockPresenter: UINavigationController) {
        let mockPresenter = UINavigationController()
        let deviceCenterUseCase = MockDeviceCenterUseCase()
        let deviceListAssets = DeviceListAssets(
            title: "Device List",
            currentDeviceTitle: "This device",
            otherDevicesTitle: "Other devices",
            deviceDefaultName: "",
            backupStatuses: [
                BackupStatus(status: .upToDate, title: "", colorName: "blue", iconName: "circle.fill")
            ]
        )
        let sut = DeviceListViewRouter(
            navigationController: mockPresenter,
            deviceCenterUseCase: deviceCenterUseCase,
            deviceListAssets: deviceListAssets)
        
        return (sut, mockPresenter)
    }
}
