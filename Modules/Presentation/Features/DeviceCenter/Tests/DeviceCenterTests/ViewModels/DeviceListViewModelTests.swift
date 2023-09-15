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

    func testFilterDevices_withSearchText_matchingPartialDeviceName() async {
        let (viewModel, expectation, cancellables) = await makeSUTForSearch(searchText: "device")
        
        let expectedDeviceNames = ["device1", "device2"]
        
        await fulfillment(of: [expectation], timeout: 2.0)
        
        let foundDeviceNames = viewModel.filteredDevices.map(\.name)
        XCTAssertEqual(expectedDeviceNames, foundDeviceNames)
        
        cancellables.forEach { $0.cancel() }
    }

    func testFilterDevices_withSearchText_matchingDeviceName() async {
        let (viewModel, expectation, cancellables) = await makeSUTForSearch(searchText: "device1")
        
        let expectedDeviceNames = ["device1"]
        
        await fulfillment(of: [expectation], timeout: 2.0)
        
        let foundDeviceNames = viewModel.filteredDevices.map(\.name)
        XCTAssertEqual(expectedDeviceNames, foundDeviceNames)
        
        cancellables.forEach { $0.cancel() }
    }

    func testFilterDevices_withSearchText_whenNoMatchFound() async {
        let (viewModel, expectation, cancellables) = await makeSUTForSearch(searchText: "fake_name")
        
        await fulfillment(of: [expectation], timeout: 2.0)
        
        XCTAssertTrue(viewModel.filteredDevices.isEmpty)
        
        cancellables.forEach { $0.cancel() }
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
        
        let expectedActions: [DeviceCenterActionType] = [.cameraUploads, .info, .rename]
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
        
        let expectedActions: [DeviceCenterActionType] = [.info, .rename]
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
    
    private func makeSUTForSearch(
        searchText: String? = nil
    ) async -> (
        viewModel: DeviceListViewModel,
        expectation: XCTestExpectation,
        cancellables: Set<AnyCancellable>
    ) {
        let devices = devices()
        let viewModel = makeSUT(
            devices: devices,
            currentDeviceId: mockCurrentDeviceId
        )
        let userDevices = await viewModel.fetchUserDevices()
        await viewModel.arrangeDevices(userDevices)
        
        var cancellables = Set<AnyCancellable>()
        var expectationDescription = "Filtered devices should update"
        
        if let searchText = searchText {
            expectationDescription += " when searching for '\(searchText)'"
            viewModel.searchText = searchText
        }
        
        let expectation = XCTestExpectation(description: expectationDescription)
        
        viewModel.$filteredDevices
            .sink { _ in
                if viewModel.isSearchActive {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        return (viewModel, expectation, cancellables)
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
            refreshDevicesPublisher: PassthroughSubject<Void, Never>(),
            updateInterval: updateInterval,
            router: MockDeviceListViewRouter(),
            deviceCenterBridge: DeviceCenterBridge(),
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
                ),
                DeviceCenterAction(
                    type: .sort
                )
            ]
        )
        
        trackForMemoryLeaks(on: sut, file: file, line: line)
        return sut
    }
}
