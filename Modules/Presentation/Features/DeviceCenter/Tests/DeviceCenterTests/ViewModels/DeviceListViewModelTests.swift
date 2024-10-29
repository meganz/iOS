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
    
    func testLoadUserDevices_returnsUserDevices() async throws {
        let sourceDevices = devices()
        let viewModel = makeSUT(
            devices: sourceDevices,
            currentDeviceId: mockCurrentDeviceId
        )
        let expectedCurrentDeviceName = "device1"
        let expectedOtherDeviceNames = ["device2"]
        
        let cancellables = try await setUpSubscriptionAndAwaitExpectation(
            viewModel: viewModel) { otherDevices in
                XCTAssertEqual(viewModel.currentDevice?.name, expectedCurrentDeviceName)
                XCTAssertEqual(otherDevices.map(\.name), expectedOtherDeviceNames)
            }
        
        cancellables.forEach { $0.cancel() }
    }
    
    func testArrangeDevices_withCurrentDeviceId_loadsCurrentDevice() async throws {
        let devices = devices()
        let currentDevice = devices.first {$0.id == mockCurrentDeviceId}
        let viewModel = makeSUT(
            devices: devices,
            currentDeviceId: mockCurrentDeviceId
        )
        let currentDeviceName = try XCTUnwrap(currentDevice?.name)
        
        let cancellables = try await setUpSubscriptionAndAwaitExpectation(
            viewModel: viewModel) { otherDevices in
                XCTAssertEqual(viewModel.currentDevice?.name, currentDeviceName)
                XCTAssertTrue(otherDevices.count == 1)
            }
        
        cancellables.forEach { $0.cancel() }
    }
    
    func testFilterDevices_withSearchText_matchingPartialDeviceName() async {
        let (viewModel, expectation, cancellables) = await makeSUTForSearch(searchText: "device")
        
        let expectedDeviceNames = ["device1", "device2"]
        
        await fulfillment(of: [expectation], timeout: 1.0)
        
        let foundDeviceNames = viewModel.filteredDevices.map(\.name)
        XCTAssertEqual(expectedDeviceNames, foundDeviceNames)
        
        cancellables.forEach { $0.cancel() }
    }

    func testFilterDevices_withSearchText_matchingDeviceName() async {
        let (viewModel, expectation, cancellables) = await makeSUTForSearch(searchText: "device1")
        
        let expectedDeviceNames = ["device1"]
        
        await fulfillment(of: [expectation], timeout: 1.0)
        
        let foundDeviceNames = viewModel.filteredDevices.map(\.name)
        XCTAssertEqual(expectedDeviceNames, foundDeviceNames)
        
        cancellables.forEach { $0.cancel() }
    }

    func testFilterDevices_withSearchText_whenNoMatchFound() async {
        let (viewModel, expectation, cancellables) = await makeSUTForSearch(searchText: "fake_name")
        
        await fulfillment(of: [expectation], timeout: 1.0)
        
        XCTAssertTrue(viewModel.filteredDevices.isEmpty)
        
        cancellables.forEach { $0.cancel() }
    }
    
    func testIsFiltered_withEmptySearchText_shouldReturnFalse() async {
        let (viewModel, expectation, cancellables) = await makeSUTForSearch(searchText: "device1")
        
        let expectedDeviceNames = ["device1"]
        
        await fulfillment(of: [expectation], timeout: 1.0)
        
        let foundDeviceNames = viewModel.filteredDevices.map(\.name)
        XCTAssertEqual(expectedDeviceNames, foundDeviceNames)
        
        XCTAssertTrue(viewModel.isFiltered)
        
        viewModel.searchText = ""
        
        XCTAssertFalse(viewModel.isFiltered)
        
        cancellables.forEach { $0.cancel() }
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
        
        try await Task.sleep(nanoseconds: 100_000_000)
    
        task.cancel()
        
        XCTAssertTrue(task.isCancelled, "Task should be cancelled")
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
        
        var backup6 = BackupEntity(id: 6, name: "backup1", userAgent: "Mozilla/5.0", type: .cameraUpload)
        backup6.backupStatus = .upToDate
        var backup7 = BackupEntity(id: 7, name: "backup1", userAgent: "Mozilla/5.0", type: .upSync)
        backup7.backupStatus = .upToDate
        
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
        
        let device6 = DeviceEntity(
            id: mockCurrentDeviceId,
            name: "device6",
            backups: [backup6],
            status: .upToDate
        )
        
        let device7 = DeviceEntity(
            id: mockCurrentDeviceId,
            name: "device7",
            backups: [backup7],
            status: .upToDate
        )
        
        let viewModel = makeSUT(
            devices: [device1, device2, device3, device4, device5, device6, device7],
            currentDeviceId: mockCurrentDeviceId
        )
        
        let userDevices = await viewModel.fetchUserDevices()
        await viewModel.arrangeDevices(userDevices)
        
        let userAgent = try XCTUnwrap(device1.backups?.first?.userAgent)
        let foundIconName = viewModel.deviceIconName(userAgent: userAgent, isMobile: true)
        let expectedIconName = "iphone"
        
        XCTAssertEqual(foundIconName, expectedIconName)
        
        let userAgent2 = try XCTUnwrap(device2.backups?.first?.userAgent)
        let foundIconName2 = viewModel.deviceIconName(userAgent: userAgent2, isMobile: true)
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
        
        let userAgent6 = try XCTUnwrap(device6.backups?.first?.userAgent)
        let foundIconName6 = viewModel.deviceIconName(userAgent: userAgent6, isMobile: true)
        let expectedIconName6 = "mobile"
        
        XCTAssertEqual(foundIconName6, expectedIconName6)
        
        let userAgent7 = try XCTUnwrap(device7.backups?.first?.userAgent)
        let foundIconName7 = viewModel.deviceIconName(userAgent: userAgent7, isMobile: false)
        let expectedIconName7 = "pc"
        
        XCTAssertEqual(foundIconName7, expectedIconName7)
    }
    
    func testHasNetworkConnection_whenConnected_shouldReturnTrue() async throws {
        let mockNetworkMonitorUseCase = MockNetworkMonitorUseCase(connected: true)
        let viewModel = makeSUT(
            networkMonitorUseCase: mockNetworkMonitorUseCase
        )
        
        let userDevices = await viewModel.fetchUserDevices()
        await viewModel.arrangeDevices(userDevices)
        
        await viewModel.updateInternetConnectionStatus()
        
        XCTAssertTrue(viewModel.hasNetworkConnection)
    }
    
    func testHasNetworkConnection_whenDisconnected_shouldReturnFalse() async throws {
        let mockNetworkMonitorUseCase = MockNetworkMonitorUseCase(connected: false)
        let viewModel = makeSUT(
            networkMonitorUseCase: mockNetworkMonitorUseCase
        )
        
        let userDevices = await viewModel.fetchUserDevices()
        await viewModel.arrangeDevices(userDevices)
        
        await viewModel.updateInternetConnectionStatus()
        
        XCTAssertFalse(viewModel.hasNetworkConnection)
    }

    func testHasNetworkConnection_whenConnectionChanges_shouldUpdateDynamically() async throws {
        let expectation = XCTestExpectation(description: "Connection status should change dynamically")
        let connectionSequence = AsyncStream<Bool> { continuation in
            continuation.yield(false)
            continuation.yield(true)
            continuation.finish()
        }.eraseToAnyAsyncSequence()
        
        let mockNetworkMonitorUseCase = MockNetworkMonitorUseCase(connected: false, connectionSequence: connectionSequence)
        let viewModel = makeSUT(networkMonitorUseCase: mockNetworkMonitorUseCase)
        
        await viewModel.updateInternetConnectionStatus()
        
        XCTAssertFalse(viewModel.hasNetworkConnection)
        
        Task {
            while !viewModel.hasNetworkConnection {
                await Task.yield()
            }
            expectation.fulfill()
        }
        
        await fulfillment(of: [expectation], timeout: 1.0)
        
        XCTAssertTrue(viewModel.hasNetworkConnection)
    }
    
    // MARK: - Helpers
    
    private func setUpSubscriptionAndAwaitExpectation(
        viewModel: DeviceListViewModel,
        completion: @escaping ([DeviceCenterItemViewModel]) -> Void
    ) async throws -> Set<AnyCancellable> {
        let expectation = XCTestExpectation(description: "Wait for otherDevices update")
        var cancellables = Set<AnyCancellable>()

        viewModel.$otherDevices
           .filter { !$0.isEmpty }
           .first()
           .sink(receiveValue: { otherDevices in
               completion(otherDevices)
               expectation.fulfill()
           })
           .store(in: &cancellables)
        
        let userDevices = await viewModel.fetchUserDevices()
        await viewModel.arrangeDevices(userDevices)
        
        await fulfillment(of: [expectation], timeout: 1.0)
        
        return cancellables
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
    
    private let defaultDeviceListAssets = DeviceListAssets(title: "", currentDeviceTitle: "", otherDevicesTitle: "", deviceDefaultName: "")
    private let defaultEmptyStateAssets = EmptyStateAssets(image: "", title: "")
    private let defaultSearchAssets = SearchAssets(placeHolder: "", cancelTitle: "", backgroundColor: .black)
    private let defaultActions = [
        ContextAction(type: .cameraUploads),
        ContextAction(type: .info),
        ContextAction(type: .rename),
        ContextAction(type: .sort)
    ]
    private let defaultIconNames: [BackupDeviceTypeEntity: String] = [
        .android: "android",
        .iphone: "iphone",
        .linux: "pcLinux",
        .mac: "pcMac",
        .win: "pcWindows",
        .defaultMobile: "mobile",
        .defaultPc: "pc"
    ]
    
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
        
        var cancellable = Set<AnyCancellable>()
        var expectationDescription = "Filtered devices should update"
        
        if let searchText = searchText {
            expectationDescription += " when searching for '\(searchText)'"
            viewModel.searchText = searchText
        }
        
        let expectation = XCTestExpectation(description: expectationDescription)
        
        viewModel.$filteredDevices
            .dropFirst()
            .sink { _ in
                expectation.fulfill()
            }
            .store(in: &cancellable)
        
        return (viewModel, expectation, cancellable)
    }
    
    private func makeSUT(
        devices: [DeviceEntity] = [],
        currentDeviceId: String = "",
        updateInterval: UInt64 = 1,
        networkMonitorUseCase: MockNetworkMonitorUseCase = MockNetworkMonitorUseCase(),
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
            deviceCenterUseCase: MockDeviceCenterUseCase(
                devices: devices,
                currentDeviceId: currentDeviceId
            ),
            nodeUseCase: MockNodeDataUseCase(),
            networkMonitorUseCase: networkMonitorUseCase,
            deviceListAssets: defaultDeviceListAssets,
            emptyStateAssets: defaultEmptyStateAssets,
            searchAssets: defaultSearchAssets,
            backupStatuses: backupStatusEntities.compactMap { BackupStatus(status: $0) },
            deviceCenterActions: defaultActions,
            deviceIconNames: defaultIconNames
        )
        
        trackForMemoryLeaks(on: sut, file: file, line: line)
        return sut
    }
}
