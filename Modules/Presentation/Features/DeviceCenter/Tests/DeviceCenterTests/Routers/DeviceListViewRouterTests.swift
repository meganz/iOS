@testable import DeviceCenter
import MEGADomain
import MEGADomainMock
import MEGATest
import SwiftUI
import XCTest

final class DeviceListViewRouterTests: XCTestCase {
    @MainActor
    func testBuild_rendersCorrectViewController() throws {
        let (sut, _) = try makeSUT()
        
        let resultViewController = sut.build()
        
        XCTAssert(resultViewController is UIHostingController<DeviceListView>)
    }
    
    @MainActor
    func testStart_pushCorrectViewController() throws {
        let (sut, mockPresenter) = try makeSUT()
        
        sut.start()
        
        let viewController = try XCTUnwrap(mockPresenter.viewControllers.first)
        
        XCTAssertTrue(viewController is UIHostingController<DeviceListView>)
    }
    
    // MARK: - Helpers
    @MainActor
    private func makeSUT() throws -> (sut: DeviceListViewRouter, mockPresenter: UINavigationController) {
        let mockPresenter = UINavigationController()
        let deviceCenterUseCase = MockDeviceCenterUseCase()
        let cameraUploadsUseCase = MockCameraUploadsUseCase(
            cuNode: NodeEntity(
                name: "Camera Uploads",
                handle: 1
            ),
            isCameraUploadsNode: true
        )
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
                cancelTitle: "",
                backgroundColor: Color(.systemBackground)
            ),
            deviceCenterActions: [],
            deviceIconNames: [:]
        )
        
        let sut = DeviceListViewRouter(
            navigationController: mockPresenter,
            deviceCenterBridge: DeviceCenterBridge(),
            deviceCenterUseCase: deviceCenterUseCase,
            nodeUseCase: MockNodeDataUseCase(),
            cameraUploadsUseCase: cameraUploadsUseCase,
            networkMonitorUseCase: MockNetworkMonitorUseCase(),
            notificationCenter: NotificationCenter.default,
            deviceCenterAssets: deviceListAssets
        )
        
        return (sut, mockPresenter)
    }
}
