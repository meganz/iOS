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
    
    let stubbedStatusAssets = StatusAssets(
        title: "",
        color: .blue,
        iconName: ""
    )
    
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
    
    private let defaultActions = [
        ContextAction(type: .cameraUploads),
        ContextAction(type: .info),
        ContextAction(type: .rename),
        ContextAction(type: .sort)
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
    
    @MainActor
    private func makeSUT(
        devices: [DeviceEntity] = [],
        currentDeviceId: String = "",
        updateInterval: UInt64 = 1,
        networkMonitorUseCase: MockNetworkMonitorUseCase = MockNetworkMonitorUseCase(),
        deviceIconProvider: MockDeviceIconProvider = MockDeviceIconProvider()
    ) -> DeviceListViewModel {
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
            backupStatusProvider: MockBackupStatusProvider(stubbedDeviceDisplayAssets: stubbedStatusAssets),
            deviceCenterActions: defaultActions,
            deviceIconProvider: deviceIconProvider,
            currentDeviceUUID: ""
        )
        
        trackForMemoryLeaks(on: sut)
        return sut
    }
}
