import Combine
@testable import DeviceCenter
import DeviceCenterMocks
import MEGADomain
import MEGADomainMock
import MEGATest
import SwiftUI
import XCTest

final class DeviceListViewModelTests: XCTestCase {
    let mockCurrentDeviceId = "1"
    let mockAuxDeviceId = "2"
    
    func testLoadUserDevices_returnsUserDevices() async {
        let devices = devices()
        let viewModel = makeSUT(
            devices: devices,
            currentDeviceId: mockCurrentDeviceId
        )
        
        let fetchedDevices = await viewModel.fetchUserDevices()
        await viewModel.arrangeDevices(fetchedDevices)
        
        XCTAssertEqual(fetchedDevices.map(\.name), devices.map(\.name))
    }
    
    func testArrangeDevices_withCurrentDeviceId_loadsCurrentDevice() async throws {
        let devices = devices()
        let currentDevice = devices.first {$0.id == mockCurrentDeviceId}
        let viewModel = makeSUT(
            devices: devices,
            currentDeviceId: mockCurrentDeviceId
        )
        
        let userDevices = await viewModel.fetchUserDevices()
        await viewModel.arrangeDevices(userDevices)
        
        let currentDeviceName = try XCTUnwrap(currentDevice?.name)
        XCTAssertEqual(viewModel.currentDevice?.name, currentDeviceName)
        XCTAssertTrue(viewModel.otherDevices.isNotEmpty)
        XCTAssertTrue(viewModel.otherDevices.count == 1)
    }
        
    func testFilterDevices_withSearchText_matchingDeviceName() async {
        let devices = devices()
        
        let viewModel = makeSUT(
            devices: devices,
            currentDeviceId: mockCurrentDeviceId
        )
        
        let userDevices = await viewModel.fetchUserDevices()
        await viewModel.arrangeDevices(userDevices)
        
        viewModel.searchText = "device"
        
        let expectedDeviceNames = ["device1", "device2"]
        let foundDeviceNames = viewModel.filteredDevices.map(\.name)
        XCTAssertEqual(expectedDeviceNames, foundDeviceNames)
        
        viewModel.searchText = "1"
        
        let expectedDeviceNames2 = ["device1"]
        let foundDeviceNames2 = viewModel.filteredDevices.map(\.name)
        XCTAssertEqual(foundDeviceNames2, expectedDeviceNames2)

        viewModel.searchText = "fake_name"
        XCTAssertTrue(viewModel.filteredDevices.isEmpty)
    }
    
    func testFilterDevices_withEmptySearchText_shouldReturnTheSameDevices() async {
        let devices = devices()
        
        let viewModel = makeSUT(
            devices: devices,
            currentDeviceId: mockCurrentDeviceId
        )
        
        let userDevices = await viewModel.fetchUserDevices()
        await viewModel.arrangeDevices(userDevices)
        
        viewModel.searchText = ""
        
        let expectedDeviceNames = devices.map(\.name)
        let foundDeviceNames = viewModel.filteredDevices.map(\.name)
        
        XCTAssertEqual(foundDeviceNames, expectedDeviceNames)
    }
    
    func testIsFiltered_withSearchTextMatchingDevices_shouldReturnTrue() async {
        let devices = devices()
        
        let viewModel = makeSUT(
            devices: devices,
            currentDeviceId: mockCurrentDeviceId
        )
        
        let userDevices = await viewModel.fetchUserDevices()
        await viewModel.arrangeDevices(userDevices)
        
        viewModel.searchText = "dev"
        
        XCTAssertTrue(viewModel.isFiltered)
    }

    func testIsFiltered_withEmptySearchText_shouldReturnFalse() async {
        let devices = devices()
        
        let viewModel = makeSUT(
            devices: devices,
            currentDeviceId: mockCurrentDeviceId
        )
        
        let userDevices = await viewModel.fetchUserDevices()
        await viewModel.arrangeDevices(userDevices)
        
        viewModel.searchText = ""
        
        XCTAssertFalse(viewModel.isFiltered)
    }
    
    func testStartAutoRefreshUserDevices_cancellation() async throws {
        let devices = devices()
        
        let viewModel = makeSUT(
            devices: devices,
            currentDeviceId: mockCurrentDeviceId,
            updateInterval: 5
        )
        
        let userDevices = await viewModel.fetchUserDevices()
        await viewModel.arrangeDevices(userDevices)
        
        let task = Task {
            try await viewModel.startAutoRefreshUserDevices()
        }
    
        task.cancel()
        
        XCTAssertTrue(task.isCancelled, "Task should be cancelled")
    }
    
    func testActionsForDevice_selectedMobileDevice_returnsCorrectActions() async throws {
        let devices = devices()
        
        let viewModel = makeSUT(
            devices: devices,
            currentDeviceId: mockCurrentDeviceId
        )
        
        let userDevices = await viewModel.fetchUserDevices()
        await viewModel.arrangeDevices(userDevices)
        
        let selectedDevice = try XCTUnwrap(devices.first {$0.id == mockCurrentDeviceId})
        
        let actions = viewModel.actionsForDevice(selectedDevice)
        
        let expectedActions: [DeviceCenterActionType] = [.cameraUploads, .rename, .info]
        let actionsType = actions?.compactMap {$0.type}
        XCTAssertEqual(actionsType, expectedActions, "Actions for the current device are incorrect")
    }
    
    func testActionsForDevice_selectedOtherDevice_returnsCorrectActions() async throws {
        let devices = devices()
        
        let viewModel = makeSUT(
            devices: devices,
            currentDeviceId: mockAuxDeviceId
        )
        
        let userDevices = await viewModel.fetchUserDevices()
        await viewModel.arrangeDevices(userDevices)
        
        let selectedDevice = try XCTUnwrap(devices.first {$0.id == mockAuxDeviceId})
        
        let actions = viewModel.actionsForDevice(selectedDevice)
        
        let expectedActions: [DeviceCenterActionType] = [.rename, .info]
        let actionsType = actions?.compactMap {$0.type}
        XCTAssertEqual(actionsType, expectedActions, "Actions for the current device are incorrect")
    }
    
    private func filteredDevices(by text: String) -> [DeviceEntity] {
        devices().filter {
            $0.name.lowercased().contains(text.lowercased())
        }
    }
    
    private func devices() -> [DeviceEntity] {
        var backup1 = BackupEntity(id: 1, name: "backup1", type: .cameraUpload)
        backup1.backupStatus = .upToDate
        var backup2 = BackupEntity(id: 2, name: "backup2", type: .upSync)
        backup2.backupStatus = .upToDate
        
        let device1 = DeviceEntity(
            id: mockCurrentDeviceId,
            name: "device1",
            backups: [
                backup1
            ],
            status: .upToDate
        )
        
        let device2 = DeviceEntity(
            id: mockAuxDeviceId,
            name: "device2",
            backups: [
                backup2
            ],
            status: .upToDate
        )
        
        return [device1, device2]
    }
    
    private func backupStatusEntities() -> [BackupStatusEntity] {
        [.upToDate, .offline, .blocked, .outOfQuota, .error, .disabled, .paused, .updating, .scanning, .initialising, .backupStopped, .noCameraUploads]
    }
    
    private func makeSUT(
        devices: [DeviceEntity],
        currentDeviceId: String,
        updateInterval: UInt64 = 1,
        file: StaticString = #file,
        line: UInt = #line
    ) -> DeviceListViewModel {
        
        let backupStatusEntities = backupStatusEntities()
        
        let sut = DeviceListViewModel(
            devicesUpdatePublisher: PassthroughSubject<[DeviceEntity], Never>(),
            updateInterval: updateInterval,
            router: MockDeviceListViewRouter(),
            deviceCenterUseCase: MockDeviceCenterUseCase(devices: devices, currentDeviceId: currentDeviceId),
            deviceListAssets:
                DeviceListAssets(
                    title: "",
                    currentDeviceTitle: "",
                    otherDevicesTitle: "",
                    deviceDefaultName: ""
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
            backupStatuses: backupStatusEntities.compactMap { BackupStatus(status: $0) },
            deviceCenterActions: [
                DeviceCenterAction(
                    type: .cameraUploads
                ),
                DeviceCenterAction(
                    type: .info
                ),
                DeviceCenterAction(
                    type: .rename
                ),
                DeviceCenterAction(
                    type: .showInBackups
                ),
                DeviceCenterAction(
                    type: .showInCD
                )
            ]
        )
        
        trackForMemoryLeaks(on: sut, file: file, line: line)
        return sut
    }
}
