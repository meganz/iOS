@testable import DeviceCenter
import MEGADomain
import MEGADomainMock
import XCTest

final class DeviceCenterItemViewModelTests: XCTestCase {
    let mockCurrentDeviceId = "1"
    let mockAuxDeviceId = "2"
    
    func testActionsForBackup_cameraUploadBackupType_returnsCorrectActions() {
        let backup = BackupEntity(
            id: 1,
            name: "backup1",
            deviceId: mockCurrentDeviceId,
            type: .cameraUpload
        )
        
        let mockUseCase = MockNodeDataUseCase(
            node: NodeEntity(
                handle: 1,
                isOutShare: false,
                isExported: false
            )
        )
        
        let viewModel = makeSUT(
            nodeUseCase: mockUseCase,
            itemType: .backup(backup)
        )
        
        viewModel.loadAvailableActions()
        let actions = viewModel.availableActions
        let actionsType = actions.compactMap {$0.type}
        let expectedActions: [DeviceCenterActionType] = [.info, .favourite, .label, .offline, .shareLink, .shareFolder, .rename, .move, .copy, .moveToTheRubbishBin]
        
        XCTAssertEqual(actionsType, expectedActions, "Actions for camera upload backup are incorrect")
    }
 
    func testActionsForBackup_otherBackupType_returnsCorrectActions() {
        let backup = BackupEntity(
            id: 1,
            name: "backup1",
            deviceId: mockCurrentDeviceId,
            type: .backupUpload
        )
        
        let mockUseCase = MockNodeDataUseCase(
            node: NodeEntity(
                handle: 1,
                isOutShare: true,
                isExported: true
            )
        )
        
        let viewModel = makeSUT(
            nodeUseCase: mockUseCase,
            itemType: .backup(backup)
        )
        
        viewModel.loadAvailableActions()
        let actions = viewModel.availableActions
        let actionsType = actions.compactMap {$0.type}
        let expectedActions: [DeviceCenterActionType] = [.info, .offline, .manageLink, .removeLink, .manageFolder, .copy]
        
        XCTAssertEqual(actionsType, expectedActions, "Actions for backup are incorrect")
    }
    
    private func backups() -> [BackupEntity] {
        var backup1 = BackupEntity(
            id: 1,
            name: "backup1",
            deviceId: mockCurrentDeviceId
        )
        
        backup1.backupStatus = .updating
        
        var backup2 = BackupEntity(
            id: 2,
            name: "backup2",
            deviceId: mockCurrentDeviceId
        )
        
        backup2.backupStatus = .upToDate
        
        var backup3 = BackupEntity(
            id: 3,
            name: "backup3",
            deviceId: mockAuxDeviceId
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
    
    private func makeSUT(
        nodeUseCase: MockNodeDataUseCase,
        itemType: DeviceCenterItemType,
        file: StaticString = #file,
        line: UInt = #line
    ) -> DeviceCenterItemViewModel {
        
        let deviceCenterUseCase = MockDeviceCenterUseCase(devices: devices(), currentDeviceId: mockCurrentDeviceId)
        let assets = ItemAssets(
            iconName: "",
            status: BackupStatus(
                status: .updating
            )
        )
        let sut = DeviceCenterItemViewModel(
            deviceCenterUseCase: deviceCenterUseCase,
            nodeUseCase: nodeUseCase,
            deviceCenterBridge: DeviceCenterBridge(),
            itemType: itemType,
            assets: assets
        )
        
        trackForMemoryLeaks(on: sut, file: file, line: line)
        return sut
    }
}
