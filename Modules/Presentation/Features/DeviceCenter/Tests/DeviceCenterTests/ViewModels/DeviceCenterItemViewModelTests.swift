@testable import DeviceCenter
import MEGADomain
import MEGADomainMock
import XCTest

final class DeviceCenterItemViewModelTests: XCTestCase {
    let mockCurrentDeviceId = "1"

    func testActionsForBackup_cameraUploadBackupType_returnsCorrectActions() {
        testActions(
            backupType: .cameraUpload,
            expectedActions: [.info]
        )
    }
 
    func testActionsForBackup_otherBackupUploadType_returnsCorrectActions() {
        testActions(
            backupType: .backupUpload,
            expectedActions: [.info]
        )
    }
    
    func testActionsForBackup_syncBackupType_returnsCorrectActions() {
        testActions(
            backupType: .upSync,
            expectedActions: [.info]
        )
    }
    
    private func testActions(backupType: BackupTypeEntity, expectedActions: [DeviceCenterActionType]) {
        let viewModel = makeSUT(
            backupType: backupType
        )
        viewModel.loadAvailableActions()
        let actions = viewModel.availableActions.compactMap { $0.type }
        XCTAssertEqual(actions, expectedActions, "Actions for \(backupType) are incorrect")
    }
    
    private func makeSUT(
        backupType: BackupTypeEntity = .invalid,
        file: StaticString = #file,
        line: UInt = #line
    ) -> DeviceCenterItemViewModel {
        let backup = BackupEntity(
            id: 1,
            name: "backup1",
            deviceId: mockCurrentDeviceId,
            rootHandle: 1,
            type: backupType,
            status: .upToDate
        )
        let device = DeviceEntity(
            id: mockCurrentDeviceId,
            name: "device1",
            backups: [backup],
            status: .upToDate
        )
        let node = NodeEntity(
            handle: 1
        )
        let nodeUseCase = MockNodeDataUseCase(
            nodes: [node],
            node: node
        )
        let deviceCenterUseCase = MockDeviceCenterUseCase(
            devices: [device],
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
            deviceCenterBridge: DeviceCenterBridge(),
            itemType: .backup(backup),
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
