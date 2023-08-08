@testable import DeviceCenter
import DeviceCenterMocks
import MEGADomain
import MEGADomainMock
import MEGATest
import SwiftUI
import XCTest

final class DeviceListViewModelTests: XCTestCase {
    
    let mockCurrentDeviceId = "1"
    
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
        XCTAssertEqual(expectedDeviceNames2, foundDeviceNames2)

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
        
        XCTAssertEqual(viewModel.filteredDevices.map(\.name), devices.map(\.name))
    }
    
    func testIsFiltered_withSearchTextMatchingDevices_shouldReturnTrue() {
        let devices = devices()
        
        let viewModel = makeSUT(
            devices: devices,
            currentDeviceId: mockCurrentDeviceId
        )
        
        viewModel.searchText = "dev"
        
        XCTAssertTrue(viewModel.isFiltered)
    }

    func testIsFiltered_withEmptySearchText_shouldReturnFalse() {
        let devices = devices()
        
        let viewModel = makeSUT(
            devices: devices,
            currentDeviceId: mockCurrentDeviceId
        )
        
        viewModel.searchText = ""
        
        XCTAssertFalse(viewModel.isFiltered)
    }
    
    private func filteredDevices(by text: String) -> [DeviceEntity] {
        devices().filter {
            $0.name.lowercased().contains(text.lowercased())
        }
    }
    
    private func devices() -> [DeviceEntity] {
        var backup1 = BackupEntity(id: 1, name: "backup1")
        backup1.backupStatus = .upToDate
        var backup2 = BackupEntity(id: 2, name: "backup2")
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
            id: "2",
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
    
    private func makeSUT(devices: [DeviceEntity], currentDeviceId: String, file: StaticString = #file, line: UInt = #line) -> DeviceListViewModel {
        let backupStatusEntities = backupStatusEntities()
        
        let sut = DeviceListViewModel(
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
            backupStatuses: backupStatusEntities.compactMap { BackupStatus(status: $0) }
        )
        
        return sut
    }
}
