@testable import DeviceCenter
import DeviceCenterMocks
import MEGADomain
import MEGADomainMock
import XCTest

@MainActor
final class DeviceCenterItemViewModelTests: XCTestCase {
    let mockCurrentDeviceId = "1"
    
    func testActions_forCurrentNewDeviceWithoutCU_returnsCorrectActions() {
        let deviceID = "deviceID"
        let device = createDevice(id: deviceID, status: .noCameraUploads)
        let expectedActions: [ContextAction.Category] = [.cameraUploads]
        
        executeAndVerifyDeviceActions(
            device: device,
            expectedActions: expectedActions,
            currentDeviceUUID: deviceID,
            errorMessage: "The actions for the current new device are incorrect"
        )
    }

    func testExecuteMainAction_forCurrentDeviceWithCU_returnsCorrectActions() {
        let device = createDevice(
            id: mockCurrentDeviceId,
            status: .upToDate
        )
        let expectedActions: [ContextAction.Category] = [.info, .cameraUploads, .rename]
        
        executeAndVerifyDeviceActions(
            device: device,
            expectedActions: expectedActions,
            isCUActionAvailable: true,
            errorMessage: "The actions for the current device are incorrect"
        )
    }

    func testExecuteMainAction_forOtherDevice_returnsCorrectActions() {
        let device = createDevice(
            id: mockCurrentDeviceId,
            status: .upToDate
        )
        let expectedActions: [ContextAction.Category] = [.info, .rename]
        
        executeAndVerifyDeviceActions(
            device: device,
            expectedActions: expectedActions,
            errorMessage: "The actions for a device other than the current one are incorrect"
        )
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
    
    private func createDevice(
        id: String = "defaultID",
        name: String = "device",
        backups: [BackupEntity] = [],
        status: BackupStatusEntity
    ) -> DeviceEntity {
        DeviceEntity(
            id: id,
            name: name,
            backups: backups,
            status: status
        )
    }
    
    private func executeAndVerifyDeviceActions(
        device: DeviceEntity,
        expectedActions: [ContextAction.Category],
        isCUActionAvailable: Bool = false,
        currentDeviceUUID: String = "",
        errorMessage: String
    ) {
        let viewModel = makeSUT(
            itemType: .device(device),
            isCUActionAvailable: isCUActionAvailable,
            currentDeviceUUID: currentDeviceUUID
        )
        
        viewModel.executeMainAction()
        let actions = viewModel.availableActions.compactMap { $0.type }
        
        XCTAssertEqual(
            actions,
            expectedActions, errorMessage
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
        isCUActionAvailable: Bool = false,
        currentDeviceUUID: String = "device"
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
                    ContextAction(
                        type: .info,
                        title: "Info",
                        icon: "info"
                    )
                ],
                .cameraUploads: [
                    ContextAction(
                        type: .cameraUploads,
                        title: "Camera Uploads",
                        icon: "cameraUploads"
                    )
                ],
                .rename: [
                    ContextAction(
                        type: .rename,
                        title: "Rename",
                        icon: "rename"
                    )
                ]
            ],
            isCUActionAvailable: isCUActionAvailable,
            assets: assets,
            currentDeviceUUID: {
                currentDeviceUUID
            }
        )
        
        trackForMemoryLeaks(on: sut)
        return sut
    }
}
