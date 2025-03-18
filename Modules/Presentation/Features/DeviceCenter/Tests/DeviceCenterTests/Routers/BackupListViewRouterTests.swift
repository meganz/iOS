import Combine
@testable import DeviceCenter
import DeviceCenterMocks
import MEGADomain
import MEGADomainMock
import MEGATest
import SwiftUI
import XCTest

final class BackupListsViewRouterTests: XCTestCase {
    @MainActor
    func testBuild_rendersCorrectViewController() throws {
        let (sut, _) = try makeSUT()
        
        let resultViewController = sut.build()
        
        XCTAssert(resultViewController is UIHostingController<BackupListView>)
    }
    
    @MainActor
    func testStart_pushCorrectViewController() throws {
        let (sut, mockPresenter) = try makeSUT()
        
        sut.start()
        
        let viewController = try XCTUnwrap(mockPresenter.viewControllers.first)
        
        XCTAssertTrue(viewController is UIHostingController<BackupListView>)
    }
    
    // MARK: - Helpers
    
    @MainActor
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
            deviceCenterActions: [],
            backupStatusProvider: MockBackupStatusProvider(statuses: [])
        )
        
        trackForMemoryLeaks(on: sut, file: file, line: line)
        return (sut, mockPresenter)
    }
}
