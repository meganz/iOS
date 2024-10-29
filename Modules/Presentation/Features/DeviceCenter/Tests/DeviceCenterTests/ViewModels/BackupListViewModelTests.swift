import Combine
@testable import DeviceCenter
import DeviceCenterMocks
import MEGADomain
import MEGADomainMock
import SwiftUI
import XCTest

final class BackupListViewModelTests: XCTestCase {
    let mockCurrentDeviceId = "1"
    let mockCurrentDeviceName = "device1"
    let mockAuxDeviceId = "2"
    let mockAuxDeviceName = "device2"
    
    func test_loadAssets_matchesBackupStatuses() {
        var backup = BackupEntity(
            id: 1,
            name: "backup1"
        )
        
        let viewModel = makeSUT(
            selectedDevice: SelectedDevice(
                id: mockCurrentDeviceId,
                name: mockCurrentDeviceName,
                backups: [backup]
            )
        )
        
        for status in backupStatusEntities() {
            backup.backupStatus = status
            validateCurrentStatus(viewModel, backup)
        }
    }
    
    func testLoadBackupsModels_backupsWithDifferentStatus_loadsBackupModels() {
        let backups = backups()
        let viewModel = makeSUT(
            selectedDevice: SelectedDevice(
                id: mockCurrentDeviceId,
                name: mockCurrentDeviceName,
                backups: backups
            )
        )
        
        viewModel.loadBackupsModels()
        
        XCTAssertEqual(viewModel.backupModels.count, 3)
        
        let expectedBackupNames = backups.map(\.name)
        let foundBackupNames = viewModel.backupModels.map(\.name)
        XCTAssertEqual(foundBackupNames, expectedBackupNames)
    }
    
    func testFilterBackups_withSearchText_matchingPartialBackupName() async {
        let (viewModel, expectation, cancellables) = await makeSUTForSearch(searchText: "backup")
        
        let expectedBackupNames = ["backup1", "backup2", "backup3"]
        
        await fulfillment(of: [expectation], timeout: 2.0)
        
        let foundBackupNames = viewModel.filteredBackups.map(\.name)
        XCTAssertEqual(expectedBackupNames, foundBackupNames)
        
        cancellables.forEach { $0.cancel() }
    }

    func testFilterBackups_withSearchText_matchingBackupName() async {
        let (viewModel, expectation, cancellables) = await makeSUTForSearch(searchText: "backup1")
        
        let expectedBackupNames = ["backup1"]
        
        await fulfillment(of: [expectation], timeout: 2.0)
        
        let foundBackupNames = viewModel.filteredBackups.map(\.name)
        XCTAssertEqual(expectedBackupNames, foundBackupNames)
        
        cancellables.forEach { $0.cancel() }
    }

    func testFilterBackups_withSearchText_whenNoMatchFound() async {
        let (viewModel, expectation, cancellables) = await makeSUTForSearch(searchText: "fake_name")
        
        await fulfillment(of: [expectation], timeout: 2.0)
        
        XCTAssertTrue(viewModel.filteredBackups.isEmpty)
        
        cancellables.forEach { $0.cancel() }
    }
    
    func testFilterBackups_withEmptySearchText_shouldReturnTheSameBackups() {
        let backups = backups()
        let viewModel = makeSUT(
            selectedDevice: SelectedDevice(
                id: mockCurrentDeviceId,
                name: mockCurrentDeviceName,
                backups: backups
            )
        )
        
        viewModel.searchText = ""
        
        let expectedBackupNames = backups.map(\.name)
        let foundBackupNames = viewModel.backupModels.map(\.name)
        XCTAssertEqual(foundBackupNames, expectedBackupNames)
    }
    
    func testFilterAndLoadCurrentDeviceBackups_loadsBackupsForCurrentDevice() async {
        let backups = backups()
        let userGroupedBackups = Dictionary(grouping: backups, by: \.deviceId)
        
        let viewModel = makeSUT(
            selectedDevice: SelectedDevice(
                id: mockCurrentDeviceId,
                name: mockCurrentDeviceName,
                backups: userGroupedBackups[mockCurrentDeviceId] ?? []
            )
        )
        
        let expectedBackupNames = userGroupedBackups[mockCurrentDeviceId]?.map(\.name)
        let foundBackupNames = viewModel.selectedDevice.backups.map(\.name)
        
        await viewModel.updateCurrentDevice(devices())
        XCTAssertEqual(foundBackupNames, expectedBackupNames)
        
        let viewModel2 = makeSUT(
            selectedDevice: SelectedDevice(
                id: mockAuxDeviceId,
                name: mockAuxDeviceName,
                backups: userGroupedBackups[mockAuxDeviceId] ?? []
            )
        )
        
        await viewModel2.updateCurrentDevice(devices())
        
        let expectedBackupNames2 = userGroupedBackups[mockAuxDeviceId]?.map(\.name)
        let foundBackupNames2 = viewModel2.selectedDevice.backups.map(\.name)
        
        XCTAssertEqual(foundBackupNames2, expectedBackupNames2)
    }
    
    func testUpdateDeviceStatusesAndNotify_fetchesAndUpdateDevices() async {
        let backups = backups()
        let userGroupedBackups = Dictionary(grouping: backups, by: \.deviceId)
        let mockUseCase = MockDeviceCenterUseCase(devices: devices(), currentDeviceId: mockCurrentDeviceId)
        
        let viewModel = makeSUT(
            selectedDevice: SelectedDevice(
                id: mockCurrentDeviceId,
                name: mockCurrentDeviceName,
                backups: userGroupedBackups[mockCurrentDeviceId] ?? []
            ),
            deviceCenterUseCase: mockUseCase
        )
        
        await viewModel.syncDevicesAndLoadBackups()
        let expectedBackupNames = userGroupedBackups[mockCurrentDeviceId]?.map(\.name)
        let foundBackupNames = viewModel.selectedDevice.backups.map(\.name)
        
        XCTAssertEqual(foundBackupNames, expectedBackupNames)
    }
    
    func testUpdateDeviceStatusesAndNotify_cancellation() async throws {
        let backups = backups()
        let userGroupedBackups = Dictionary(grouping: backups, by: \.deviceId)
        let mockUseCase = MockDeviceCenterUseCase(devices: devices(), currentDeviceId: mockCurrentDeviceId)
        
        let viewModel = makeSUT(
            selectedDevice: SelectedDevice(
                id: mockCurrentDeviceId,
                name: mockCurrentDeviceName,
                backups: userGroupedBackups[mockCurrentDeviceId] ?? []
            ),
            deviceCenterUseCase: mockUseCase,
            updateInterval: 5
        )
        
        let task = Task {
            try await viewModel.updateDeviceStatusesAndNotify()
        }
        
        try await Task.sleep(nanoseconds: 100_000_000)
        
        task.cancel()
        
        XCTAssertTrue(task.isCancelled, "Task should be cancelled")
    }
    
    func testActionsForDevice_currentDeviceWithoutCameraUpload_returnsCorrectActions() {
        let actionsType = makeSUTForDevices(
            deviceId: mockCurrentDeviceId,
            deviceName: mockCurrentDeviceName,
            isCurrent: true,
            isNewDeviceWithoutCU: true,
            backupType: .cameraUpload
        )
        
        let expectedActions: [ContextAction.Category] = [.cameraUploads]
        XCTAssertEqual(actionsType, expectedActions, "The actions for the current device, where the CU has never been activated, are incorrect.")
    }
    
    func testActionsForDevice_currentDeviceWithCameraUpload_returnsCorrectActions() {
        let actionsType = makeSUTForDevices(
            deviceId: mockCurrentDeviceId,
            deviceName: mockCurrentDeviceName,
            isCurrent: true,
            backupType: .cameraUpload
        )
        
        let expectedActions: [ContextAction.Category] = [.rename, .info, .cameraUploads, .sort]
        XCTAssertEqual(actionsType, expectedActions, "The actions for the current device, where the CU has been activated are incorrect.")
    }

    func testActionsForDevice_anotherDevice_returnsCorrectActions() {
        let actionsType = makeSUTForDevices(
            deviceId: mockAuxDeviceId,
            deviceName: mockAuxDeviceName,
            backupType: .upSync
        )
        
        let expectedActions: [ContextAction.Category] = [.rename, .info, .sort]
        XCTAssertEqual(actionsType, expectedActions, "Actions for another device than the current one, where the CU has never been activated are incorrect")
    }
    
    func testNetworkConnectivity_whenNotReachable_updatesHasNetworkConnectionToFalse() async {
        await verifyNetworkConnectivity(isConnected: false)
    }

    func testNetworkConnectivity_whenReachable_updatesHasNetworkConnectionToTrue() async {
        await verifyNetworkConnectivity(isConnected: true)
    }

    @MainActor
    private func verifyNetworkConnectivity(isConnected: Bool) async {
        let networkUseCase = MockNetworkMonitorUseCase(
            connected: isConnected,
            connectionSequence: AsyncStream { continuation in
                continuation.yield(isConnected)
                continuation.finish()
            }.eraseToAnyAsyncSequence()
        )
        
        let sut = makeSUT(
            selectedDevice: SelectedDevice(
                id: mockCurrentDeviceId,
                name: mockCurrentDeviceName,
                backups: []
            ),
            networkMonitorUseCase: networkUseCase
        )
        
        sut.updateInternetConnectionStatus()
        
        for await connectionStatus in networkUseCase.connectionSequence {
            XCTAssertEqual(connectionStatus, networkUseCase.isConnected())
            XCTAssertEqual(sut.hasNetworkConnection, connectionStatus)
            return
        }
    }
    
    private func backups() -> [BackupEntity] {
        var backup1 = BackupEntity(
            id: 1,
            name: "backup1",
            deviceId: mockCurrentDeviceId,
            type: .cameraUpload
        )
        
        backup1.backupStatus = .updating
        
        var backup2 = BackupEntity(
            id: 2,
            name: "backup2",
            deviceId: mockCurrentDeviceId,
            type: .upSync
        )
        
        backup2.backupStatus = .upToDate
        
        var backup3 = BackupEntity(
            id: 3,
            name: "backup3",
            deviceId: mockAuxDeviceId,
            type: .downSync
        )
        
        backup3.backupStatus = .offline
        
        return [backup1, backup2, backup3]
    }
    
    private func devices() -> [DeviceEntity] {
        let userGroupedBackups = Dictionary(grouping: backups(), by: \.deviceId)
        
        let device1 = DeviceEntity(
            id: mockCurrentDeviceId,
            name: "device1",
            backups: userGroupedBackups[mockCurrentDeviceId],
            status: .upToDate
        )
        
        let device2 = DeviceEntity(
            id: "2",
            name: "device2",
            backups: userGroupedBackups[mockAuxDeviceId],
            status: .upToDate
        )
        
        return [device1, device2]
    }
    
    private func backupStatusEntities() -> [BackupStatusEntity] {
        [.upToDate, .offline, .blocked, .outOfQuota, .error, .disabled, .paused, .updating, .scanning, .initialising, .backupStopped, .noCameraUploads]
    }
    
    private func backupTypeEntities() -> [BackupTypeEntity] {
        [.backupUpload, .cameraUpload, .mediaUpload, .twoWay, .downSync, .upSync, .invalid]
    }
    
    private func validateCurrentStatus(_ viewModel: BackupListViewModel, _ backupEntity: BackupEntity) {
        let assets = viewModel.loadAssets(for: backupEntity)
        XCTAssertNotNil(assets)
        XCTAssertEqual(assets?.backupStatus.status, backupEntity.backupStatus)
    }
    
    private func makeSUTForDevices(
        deviceId: String,
        deviceName: String,
        isCurrent: Bool = false,
        isNewDeviceWithoutCU: Bool = false,
        backupType: BackupTypeEntity
    ) -> [ContextAction.Category] {
        let mockUseCase = MockDeviceCenterUseCase(devices: devices(), currentDeviceId: deviceId)
        
        let viewModel = makeSUT(
            selectedDevice: 
                SelectedDevice(
                    id: deviceId,
                    name: deviceName,
                    isCurrent: isCurrent,
                    isNewDeviceWithoutCU: isNewDeviceWithoutCU,
                    backups: backups().filter { $0.deviceId == deviceId }
                ),
            deviceCenterUseCase: mockUseCase
        )
        
        let actions = viewModel.availableActionsForCurrentDevice()
        return actions.map { $0.type }
    }
    
    private func makeSUTForSearch(
        searchText: String? = nil
    ) async -> (
        viewModel: BackupListViewModel,
        expectation: XCTestExpectation,
        cancellables: Set<AnyCancellable>
    ) {
        let backups = backups()
        let viewModel = makeSUT(
            selectedDevice: SelectedDevice(
                id: mockCurrentDeviceId,
                name: mockCurrentDeviceName,
                backups: backups
            )
        )
        
        var cancellables = Set<AnyCancellable>()
        var expectationDescription = "Filtered backups should update"
        
        if let searchText = searchText {
            expectationDescription += " when searching for '\(searchText)'"
            viewModel.searchText = searchText
        }
        
        let expectation = XCTestExpectation(description: expectationDescription)
        
        viewModel.$filteredBackups
            .dropFirst()
            .sink { _ in
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        return (viewModel, expectation, cancellables)
    }
    
    private func makeSUT(
        selectedDevice: SelectedDevice,
        deviceCenterUseCase: MockDeviceCenterUseCase = MockDeviceCenterUseCase(),
        updateInterval: UInt64 = 1,
        networkMonitorUseCase: NetworkMonitorUseCaseProtocol = MockNetworkMonitorUseCase(),
        file: StaticString = #file,
        line: UInt = #line
    ) -> BackupListViewModel {
        
        let node = NodeEntity(handle: 1)
        let backupStatusEntities = backupStatusEntities()
        let backupTypeEntities = backupTypeEntities()
        let sut = BackupListViewModel(
            selectedDevice: selectedDevice,
            devicesUpdatePublisher: PassthroughSubject<[DeviceEntity], Never>(),
            updateInterval: updateInterval,
            deviceCenterUseCase: deviceCenterUseCase,
            nodeUseCase: MockNodeDataUseCase(
                nodes: [
                    node
                ],
                node: node
            ),
            networkMonitorUseCase: networkMonitorUseCase,
            router: MockBackupListViewRouter(),
            deviceCenterBridge: DeviceCenterBridge(),
            notificationCenter: NotificationCenter.default,
            backupListAssets:
                BackupListAssets(
                    backupTypes: backupTypeEntities.compactMap { BackupType(type: $0) }
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
            backupStatuses: backupStatusEntities.compactMap { BackupStatus(status: $0) },
            deviceCenterActions: [
                ContextAction(
                    type: .cameraUploads
                ),
                ContextAction(
                    type: .info
                ),
                ContextAction(
                    type: .rename
                ),
                ContextAction(
                    type: .sort
                )
            ]
        )
        
        trackForMemoryLeaks(on: sut, file: file, line: line)
        return sut
    }
}
