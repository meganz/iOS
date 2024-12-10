import Combine
@testable import DeviceCenter
import DeviceCenterMocks
import MEGADomain
import MEGADomainMock
import MEGASwift
import MEGATest
import SwiftUI
import XCTest

final class DeviceListViewModelTests: XCTestCase {
    let mockCurrentDeviceId = "1"
    let mockAuxDeviceId = "2"
    
    @MainActor
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
    
    @MainActor
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
    
    @MainActor
    func testFilterDevices_withSearchText_matchingPartialDeviceName() async {
        let (viewModel, expectation, cancellables) = await makeSUTForSearch(searchText: "device")
        
        let expectedDeviceNames = ["device1", "device2"]
        
        await fulfillment(of: [expectation], timeout: 1.0)
        
        let foundDeviceNames = viewModel.filteredDevices.map(\.name)
        XCTAssertEqual(expectedDeviceNames, foundDeviceNames)
        
        cancellables.forEach { $0.cancel() }
    }

    @MainActor
    func testFilterDevices_withSearchText_matchingDeviceName() async {
        let (viewModel, expectation, cancellables) = await makeSUTForSearch(searchText: "device1")
        
        let expectedDeviceNames = ["device1"]
        
        await fulfillment(of: [expectation], timeout: 1.0)
        
        let foundDeviceNames = viewModel.filteredDevices.map(\.name)
        XCTAssertEqual(expectedDeviceNames, foundDeviceNames)
        
        cancellables.forEach { $0.cancel() }
    }

    @MainActor
    func testFilterDevices_withSearchText_whenNoMatchFound() async {
        let (viewModel, expectation, cancellables) = await makeSUTForSearch(searchText: "fake_name")
        
        await fulfillment(of: [expectation], timeout: 1.0)
        
        XCTAssertTrue(viewModel.filteredDevices.isEmpty)
        
        cancellables.forEach { $0.cancel() }
    }
    
    @MainActor
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
    
    @MainActor
    func testStartAutoRefreshUserDevices_cancellation() async throws {
        let devices = devices()
        
        let viewModel = makeSUT(
            devices: devices,
            currentDeviceId: mockCurrentDeviceId,
            updateInterval: 5
        )
        
        let userDevices = await viewModel.fetchUserDevices()
        viewModel.arrangeDevices(userDevices)
        
        let task = Task {
            try await viewModel.startAutoRefreshUserDevices()
        }
        
        try await Task.sleep(nanoseconds: 500_000_000)
    
        task.cancel()
        
        try await Task.sleep(nanoseconds: 100_000_000)
        
        XCTAssertTrue(task.isCancelled, "Task should be cancelled")
    }

    @MainActor
    func testDeviceIconName_knownUserAgent_expectedIconName() async throws {
        let testData = [
            ("device1", "MEGAiOS/11.2 MEGAEnv/Dev (Darwin 22.6.0 iPhone11,2) MegaClient/4.28.2/64", true, "iphone"),
            ("device2", "Mozilla/5.0 (Android 13; M2101K6G) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/112.0.0.0 Mobile Safari/537.36", true, "android"),
            ("device3", "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:15.0) Gecko/20100101 Firefox/15.0.1", false, "pcLinux"),
            ("device4", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/42.0.2311.135 Safari/537.36 Edge/12.246", false, "pcWindows"),
            ("device5", "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_11_2) AppleWebKit/601.3.9 (KHTML, like Gecko) Version/9.0.2 Safari/601.3.9", false, "pcMac"),
            ("device6", "Mozilla/5.0", true, "mobile"),
            ("device7", "Mozilla/5.0", false, "pc")
        ]
        
        let devices = makeTestDevices(testData)
        let viewModel = makeSUT(devices: devices, currentDeviceId: mockCurrentDeviceId)
        
        let cancellables = try await setUpSubscriptionAndAwaitExpectation(
            viewModel: viewModel
        ) { _ in
            for (deviceName, _, isMobile, expectedIconName) in testData {
                do {
                    let userAgent = try XCTUnwrap(devices.first(where: { $0.name == deviceName })?.backups?.first?.userAgent)
                    let foundIconName = viewModel.deviceIconName(userAgent: userAgent, isMobile: isMobile)
                    XCTAssertEqual(foundIconName, expectedIconName, "Icon name for \(deviceName) was incorrect.")
                } catch {
                    XCTFail("Failed to unwrap userAgent for \(deviceName): \(error)")
                }
            }
        }
        
        cancellables.forEach { $0.cancel() }
    }
    
    @MainActor
    func testHasNetworkConnection_whenConnected_shouldReturnTrue() async throws {
        let connectionSequence = makeConnectionSequence([true])
        let mockNetworkMonitorUseCase = MockNetworkMonitorUseCase(
            connected: true,
            connectionSequence: connectionSequence
        )
        let viewModel = makeSUT(networkMonitorUseCase: mockNetworkMonitorUseCase)

        viewModel.updateInternetConnectionStatus()
        try await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertTrue(viewModel.hasNetworkConnection)
    }
    
    @MainActor
    func testHasNetworkConnection_whenDisconnected_shouldReturnFalse() async throws {
        let connectionSequence = makeConnectionSequence([false])
        let mockNetworkMonitorUseCase = MockNetworkMonitorUseCase(
            connected: false,
            connectionSequence: connectionSequence
        )
        let viewModel = makeSUT(networkMonitorUseCase: mockNetworkMonitorUseCase)

        viewModel.updateInternetConnectionStatus()
        try await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertFalse(viewModel.hasNetworkConnection)
    }

    @MainActor
    func testHasNetworkConnection_whenConnectionChanges_shouldUpdateDynamically() async throws {
        let expectation = XCTestExpectation(description: "Connection status should change dynamically")
        let connectionSequence = AsyncStream<Bool> { continuation in
            continuation.yield(false)
            continuation.yield(true)
            continuation.finish()
        }.eraseToAnyAsyncSequence()
        
        let mockNetworkMonitorUseCase = MockNetworkMonitorUseCase(connected: false, connectionSequence: connectionSequence)
        let viewModel = makeSUT(networkMonitorUseCase: mockNetworkMonitorUseCase)
        
        viewModel.updateInternetConnectionStatus()
        
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
    @MainActor
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
        viewModel.arrangeDevices(userDevices)
        
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
    
    @MainActor
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
        viewModel.arrangeDevices(userDevices)
        
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
    
    private func makeConnectionSequence(_ states: [Bool]) -> AnyAsyncSequence<Bool> {
        AsyncStream<Bool> { continuation in
            for state in states {
                continuation.yield(state)
            }
            continuation.finish()
        }.eraseToAnyAsyncSequence()
    }
    
    private func makeTestDevices(_ testData: [(name: String, userAgent: String, isMobile: Bool, expectedIconName: String)]) -> [DeviceEntity] {
        testData.enumerated().map { index, data in
            var backup = BackupEntity(id: index + 1, name: "backup\(index + 1)", userAgent: data.userAgent, type: .cameraUpload)
            backup.backupStatus = .upToDate
            
            return DeviceEntity(
                id: "\(index + 1)",
                name: data.name,
                backups: [backup],
                status: .upToDate
            )
        }
    }
    
    @MainActor
    private func makeSUT(
        devices: [DeviceEntity] = [],
        currentDeviceId: String = "",
        updateInterval: UInt64 = 1,
        networkMonitorUseCase: MockNetworkMonitorUseCase = MockNetworkMonitorUseCase()
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
            deviceIconNames: defaultIconNames,
            currentDeviceUUID: ""
        )
        
        trackForMemoryLeaks(on: sut)
        return sut
    }
}
