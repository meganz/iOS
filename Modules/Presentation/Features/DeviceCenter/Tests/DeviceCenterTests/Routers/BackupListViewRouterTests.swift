import Combine
@testable import DeviceCenter
import MEGADomain
import MEGADomainMock
import MEGATest
import SwiftUI
import XCTest

final class BackupListsViewRouterTests: XCTestCase {
    
    func testBuild_rendersCorrectViewController() throws {
        let (sut, _) = try makeSUT()
        
        let resultViewController = sut.build()
        
        XCTAssert(resultViewController is UIHostingController<BackupListView>)
    }
    
    func testStart_pushCorrectViewController() throws {
        let (sut, mockPresenter) = try makeSUT()
        
        sut.start()
        
        let viewController = try XCTUnwrap(mockPresenter.viewControllers.first)
        
        XCTAssertTrue(viewController is UIHostingController<BackupListView>)
    }
    
    // MARK: - Helpers
    
    private func makeSUT(
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws -> (sut: BackupListViewRouter, mockPresenter: UINavigationController) {
        
        let mockPresenter = UINavigationController()
        let networkMonitorUseCase = MockNetworkMonitorUseCase()
        let cameraUploadsUseCase = MockCameraUploadsUseCase(
            cuNode: NodeEntity(
                name: "Camera Uploads",
                handle: 1
            ),
            isCameraUploadsNode: true
        )
        
        let sut = BackupListViewRouter(
            isCurrentDevice: true,
            selectedDeviceId: "1",
            selectedDeviceName: "Device 1",
            devicesUpdatePublisher: PassthroughSubject<[DeviceEntity], Never>(),
            updateInterval: 1,
            backups: [],
            notificationCenter: NotificationCenter.default,
            deviceCenterUseCase: MockDeviceCenterUseCase(),
            nodeUseCase: MockNodeDataUseCase(),
            cameraUploadsUseCase: cameraUploadsUseCase, 
            networkMonitorUseCase: networkMonitorUseCase,
            navigationController: mockPresenter,
            deviceCenterBridge: DeviceCenterBridge(),
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
                lightBGColor: .gray,
                darkBGColor: .black
                
            ),
            backupStatuses: [
                BackupStatus(status: .upToDate, title: "", color: .blue, iconName: "circle.fill")
            ],
            deviceCenterActions: []
        )
        
        trackForMemoryLeaks(on: sut, file: file, line: line)
        return (sut, mockPresenter)
    }
}
