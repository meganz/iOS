@testable import DeviceCenter
import MEGADomain
import MEGADomainMock
import MEGATest
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
        let deviceListAssets = DeviceCenterAssets(
            deviceListAssets:
                DeviceListAssets(
                    title: "Device List",
                    currentDeviceTitle: "This device",
                    otherDevicesTitle: "Other devices",
                    deviceDefaultName: "Unknown Device"
                ),
            backupListAssets:
                BackupListAssets(
                    backupTypes: [
                        BackupType(type: .backupUpload, iconName: "backup")
                    ]
                ),
            emptyStateAssets:
                EmptyStateAssets(
                    image: "",
                    title: ""
                ),
            searchAssets: SearchAssets(
                placeHolder: "",
                cancelTitle: ""
            ),
            backupStatuses: [
                BackupStatus(status: .upToDate, title: "", color: .blue, iconName: "circle.fill")
            ],
            deviceCenterActions: [],
            deviceIconNames: [:]
        )
        
        let sut = DeviceListViewRouter(
            navigationController: mockPresenter,
            deviceCenterBridge: DeviceCenterBridge(),
            deviceCenterUseCase: deviceCenterUseCase,
            nodeUseCase: MockNodeDataUseCase(),
            networkMonitorUseCase: MockNetworkMonitorUseCase(),
            notificationCenter: NotificationCenter.default,
            deviceCenterAssets: deviceListAssets
        )
        
        return (sut, mockPresenter)
    }
}
