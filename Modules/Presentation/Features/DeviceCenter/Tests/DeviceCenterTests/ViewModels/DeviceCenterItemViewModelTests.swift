@testable import DeviceCenter
import DeviceCenterMocks
import MEGADomain
import MEGADomainMock
import XCTest

final class DeviceCenterItemViewModelTests: XCTestCase {
    let mockCurrentDeviceId = "1"

    func testActionsForDevices_returnsCorrectActions() {
        let expectedActions: [DeviceCenterActionType] = [.info]
        let device = DeviceEntity(
            id: mockCurrentDeviceId,
            name: "device1",
            backups: [],
            status: .upToDate
        )
        let viewModel = makeSUT(itemType: .device(device))
        
        viewModel.executeMainAction()
        
        let actions = viewModel.availableActions.compactMap { $0.type }
        XCTAssertEqual(actions, expectedActions, "Actions for devices are incorrect")
    }

    func testExecuteMainAction_forCUFolder_triggersInfoAction() {
        let cuFolderBackup = BackupEntity(
            id: 1,
            name: "Camera Uploads",
            deviceId: mockCurrentDeviceId,
            rootHandle: 1,
            type: .cameraUpload,
            status: .upToDate
        )
        
        executeTestForItem(
            itemType: .backup(cuFolderBackup),
            expectedName: cuFolderBackup.name,
            description: "CU Folder"
        )
    }

    func testExecuteMainAction_forSyncFolder_triggersInfoAction() {
        let syncBackup = BackupEntity(
            id: 1,
            name: "Sync",
            deviceId: mockCurrentDeviceId,
            rootHandle: 1,
            type: .upSync,
            status: .upToDate
        )
        
        executeTestForItem(
            itemType: .backup(syncBackup),
            expectedName: syncBackup.name,
            description: "Sync Folder"
        )
    }
    
    func testExecuteMainAction_forBackupFolder_triggersInfoAction() {
        let backup = BackupEntity(
            id: 1,
            name: "Backup",
            deviceId: mockCurrentDeviceId,
            rootHandle: 1,
            type: .backupUpload,
            status: .upToDate
        )
        
        executeTestForItem(
            itemType: .backup(backup),
            expectedName: backup.name,
            description: "Backup Folder"
        )
    }
    
    private func executeTestForItem(
        itemType: DeviceCenterItemType,
        expectedName: String,
        description: String
    ) {
        let expectation = self.expectation(description: description)
        let bridge = DeviceCenterBridge()
        var actualInfoModel: ResourceInfoModel?
        
        bridge.infoActionTapped = { infoModel in
            actualInfoModel = infoModel
            expectation.fulfill()
        }
        
        let viewModel = makeSUT(itemType: itemType, deviceCenterBridge: bridge)
        
        viewModel.executeMainAction()
        
        wait(for: [expectation], timeout: 3.0)
        
        XCTAssertNotNil(actualInfoModel, "Expected info action to be triggered with a non-nil ResourceInfoModel for \(description).")
        XCTAssertEqual(actualInfoModel?.name, expectedName, "Expected info action to be triggered with ResourceInfoModel matching the name for \(description).")
    }
    
    private func makeSUT(
        itemType: DeviceCenterItemType,
        deviceCenterBridge: DeviceCenterBridge = DeviceCenterBridge(),
        file: StaticString = #file,
        line: UInt = #line
    ) -> DeviceCenterItemViewModel {
        let node = NodeEntity(
            handle: 1
        )
        let nodeUseCase = MockNodeDataUseCase(
            nodes: [node],
            node: node
        )
        let deviceCenterUseCase = MockDeviceCenterUseCase(
            devices: [],
            currentDeviceId: mockCurrentDeviceId
        )
        let assets = ItemAssets(
            iconName: "",
            status: BackupStatus(
                status: .upToDate
            )
        )
        let sut = DeviceCenterItemViewModel(
            deviceCenterUseCase: deviceCenterUseCase,
            nodeUseCase: nodeUseCase,
            deviceCenterBridge: deviceCenterBridge,
            itemType: itemType,
            sortedAvailableActions: [
                .info: [
                    DeviceCenterAction(
                        type: .info,
                        title: "Info",
                        icon: "info"
                    )
                ]
            ],
            isCUActionAvailable: false,
            assets: assets
        )
        
        trackForMemoryLeaks(on: sut, file: file, line: line)
        return sut
    }
}
