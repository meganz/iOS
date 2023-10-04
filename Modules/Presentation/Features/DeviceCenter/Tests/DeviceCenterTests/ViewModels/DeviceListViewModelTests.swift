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
        
        let expectedActions: [DeviceCenterActionType] = [.cameraUploads, .rename]
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
        
        let expectedActions: [DeviceCenterActionType] = [.rename]
        let actionsType = actions?.compactMap {$0.type}
        XCTAssertEqual(actionsType, expectedActions, "Actions for the current device are incorrect")
    }
    
    func testDeviceIconName_nilUserAgent_defaultMobileIconName() async {
        let devices = devices()
        
        let viewModel = makeSUT(
            devices: devices,
            currentDeviceId: mockCurrentDeviceId
        )
        
        let userDevices = await viewModel.fetchUserDevices()
        await viewModel.arrangeDevices(userDevices)
        
        let foundIconName = viewModel.deviceIconName(userAgent: nil, isMobile: true)
        let expectedIconName = "mobile"
        
        XCTAssertEqual(foundIconName, expectedIconName)
    }

    func testDeviceIconName_nilUserAgent_defaultPCIconName() async {
        let devices = devices()
        
        let viewModel = makeSUT(
            devices: devices,
            currentDeviceId: mockCurrentDeviceId
        )
        
        let userDevices = await viewModel.fetchUserDevices()
        await viewModel.arrangeDevices(userDevices)
        
        let foundIconName = viewModel.deviceIconName(userAgent: nil, isMobile: false)
        let expectedIconName = "pc"
        
        XCTAssertEqual(foundIconName, expectedIconName)
    }

    func testDeviceIconName_knownUserAgent_expectedIconName() async throws {
        var backup1 = BackupEntity(id: 1, name: "backup1", userAgent: "MEGAiOS/11.2 MEGAEnv/Dev (Darwin 22.6.0 iPhone11,2) MegaClient/4.28.2/64", type: .cameraUpload)
        backup1.backupStatus = .upToDate
        var backup2 = BackupEntity(id: 2, name: "backup2", userAgent: "Mozilla/5.0 (Android 13; M2101K6G) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/112.0.0.0 Mobile Safari/537.36", type: .upSync)
        backup2.backupStatus = .upToDate
        var backup3 = BackupEntity(id: 3, name: "backup1", userAgent: "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:15.0) Gecko/20100101 Firefox/15.0.1", type: .cameraUpload)
        backup3.backupStatus = .upToDate
        var backup4 = BackupEntity(id: 4, name: "backup2", userAgent: "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/42.0.2311.135 Safari/537.36 Edge/12.246", type: .upSync)
        backup4.backupStatus = .upToDate
        var backup5 = BackupEntity(id: 5, name: "backup1", userAgent: "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_11_2) AppleWebKit/601.3.9 (KHTML, like Gecko) Version/9.0.2 Safari/601.3.9", type: .cameraUpload)
        backup5.backupStatus = .upToDate
        
        let device1 = DeviceEntity(
            id: mockCurrentDeviceId,
            name: "device1",
            backups: [backup1],
            status: .upToDate
        )
        
        let device2 = DeviceEntity(
            id: mockAuxDeviceId,
            name: "device2",
            backups: [backup2],
            status: .upToDate
        )
        
        let device3 = DeviceEntity(
            id: mockCurrentDeviceId,
            name: "device3",
            backups: [backup3],
            status: .upToDate
        )
        
        let device4 = DeviceEntity(
            id: mockAuxDeviceId,
            name: "device4",
            backups: [backup4],
            status: .upToDate
        )
        
        let device5 = DeviceEntity(
            id: mockCurrentDeviceId,
            name: "device5",
            backups: [backup5],
            status: .upToDate
        )
        
        let viewModel = makeSUT(
            devices: [device1, device2, device3, device4, device5],
            currentDeviceId: mockCurrentDeviceId
        )
        
        let userDevices = await viewModel.fetchUserDevices()
        await viewModel.arrangeDevices(userDevices)
        
        let userAgent = try XCTUnwrap(device1.backups?.first?.userAgent)
        let foundIconName = viewModel.deviceIconName(userAgent: userAgent, isMobile: false)
        let expectedIconName = "iphone"
        
        XCTAssertEqual(foundIconName, expectedIconName)
        
        let userAgent2 = try XCTUnwrap(device2.backups?.first?.userAgent)
        let foundIconName2 = viewModel.deviceIconName(userAgent: userAgent2, isMobile: false)
        let expectedIconName2 = "android"
        
        XCTAssertEqual(foundIconName2, expectedIconName2)
        
        let userAgent3 = try XCTUnwrap(device3.backups?.first?.userAgent)
        let foundIconName3 = viewModel.deviceIconName(userAgent: userAgent3, isMobile: false)
        let expectedIconName3 = "pcLinux"
        
        XCTAssertEqual(foundIconName3, expectedIconName3)
        
        let userAgent4 = try XCTUnwrap(device4.backups?.first?.userAgent)
        let foundIconName4 = viewModel.deviceIconName(userAgent: userAgent4, isMobile: false)
        let expectedIconName4 = "pcWindows"
        
        XCTAssertEqual(foundIconName4, expectedIconName4)
        
        let userAgent5 = try XCTUnwrap(device5.backups?.first?.userAgent)
        let foundIconName5 = viewModel.deviceIconName(userAgent: userAgent5, isMobile: false)
        let expectedIconName5 = "pcMac"
        
        XCTAssertEqual(foundIconName5, expectedIconName5)
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
            deviceCenterUseCase:
                MockDeviceCenterUseCase(
                    devices: devices,
                    currentDeviceId: currentDeviceId
                ),
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
                    type: .showInCloudDrive
                ),
                DeviceCenterAction(
                    type: .sort
                )
            ],
            deviceIconNames: [
                .android: "android",
                .iphone: "iphone",
                .linux: "pcLinux",
                .mac: "pcMac",
                .win: "pcWindows",
                .defaultMobile: "mobile",
                .defaultPc: "pc"
            ]
        )
        
        trackForMemoryLeaks(on: sut, file: file, line: line)
        return sut
    }
}
