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
        
        let sut = BackupListViewRouter(
            selectedDevice:
                SelectedDevice(
                    id: "1",
                    name: "Device 1",
                    isCurrent: true,
                    isNewDeviceWithoutCU: false,
                    backups: []
                ),
            devicesUpdatePublisher: PassthroughSubject<[DeviceEntity], Never>(),
            updateInterval: 1,
            notificationCenter: NotificationCenter.default,
            deviceCenterUseCase: MockDeviceCenterUseCase(),
            nodeUseCase: MockNodeDataUseCase(),
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
                backgroundColor: Color(.systemBackground)
                
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
