@testable import DeviceCenter
import MEGADomain
import MEGADomainMock
import XCTest

final class DeviceCenterItemViewModelTests: XCTestCase {
    let mockCurrentDeviceId = "1"

    func testActionsForBackup_cameraUploadBackupType_returnsCorrectActions() {
        testActions(
            backupType: .cameraUpload,
            isExported: false,
            isOutShared: false,
            expectedActions: [.info, .favourite, .label, .download, .shareLink, .shareFolder, .rename, .move, .copy, .moveToTheRubbishBin]
        )
        
        testActions(
            backupType: .cameraUpload,
            isExported: true,
            isOutShared: false,
            expectedActions: [.info, .favourite, .label, .download, .manageLink, .removeLink, .shareFolder, .rename, .move, .copy, .moveToTheRubbishBin]
        )
        
        testActions(
            backupType: .cameraUpload,
            isExported: false,
            isOutShared: true,
            expectedActions: [.info, .favourite, .label, .download, .shareLink, .manageShare, .rename, .move, .copy, .moveToTheRubbishBin]
        )
        
        testActions(
            backupType: .cameraUpload,
            isExported: true,
            isOutShared: true,
            expectedActions: [.info, .favourite, .label, .download, .manageLink, .removeLink, .manageShare, .rename, .move, .copy, .moveToTheRubbishBin]
        )
    }
 
    func testActionsForBackup_otherBackupUploadType_returnsCorrectActions() {
        testActions(
            backupType: .backupUpload,
            isExported: false,
            isOutShared: false,
            expectedActions: [.info, .download, .shareLink, .shareFolder, .copy]
        )
        
        testActions(
            backupType: .backupUpload,
            isExported: true,
            isOutShared: false,
            expectedActions: [.info, .download, .manageLink, .removeLink, .shareFolder, .copy]
        )
        
        testActions(
            backupType: .backupUpload,
            isExported: false,
            isOutShared: true,
            expectedActions: [.info, .download, .shareLink, .manageShare, .copy]
        )
        
        testActions(
            backupType: .backupUpload,
            isExported: true,
            isOutShared: true,
            expectedActions: [.info, .download, .manageLink, .removeLink, .manageShare, .copy]
        )
    }
    
    func testActionsForBackup_syncBackupType_returnsCorrectActions() {
        testActions(
            backupType: .upSync,
            isExported: false,
            isOutShared: false,
            expectedActions: [.info, .favourite, .label, .download, .shareLink, .shareFolder, .rename, .move, .copy, .moveToTheRubbishBin]
        )
        
        testActions(
            backupType: .upSync,
            isExported: true,
            isOutShared: false,
            expectedActions: [.info, .favourite, .label, .download, .manageLink, .removeLink, .shareFolder, .rename, .move, .copy, .moveToTheRubbishBin]
        )
        
        testActions(
            backupType: .upSync,
            isExported: false,
            isOutShared: true,
            expectedActions: [.info, .favourite, .label, .download, .shareLink, .manageShare, .rename, .move, .copy, .moveToTheRubbishBin]
        )
        
        testActions(
            backupType: .upSync,
            isExported: true,
            isOutShared: true,
            expectedActions: [.info, .favourite, .label, .download, .manageLink, .removeLink, .manageShare, .rename, .move, .copy, .moveToTheRubbishBin]
        )
    }
    
    private func testActions(backupType: BackupTypeEntity, isExported: Bool, isOutShared: Bool, expectedActions: [DeviceCenterActionType]) {
        let viewModel = makeSUT(
            backupType: backupType,
            isExported: isExported,
            isOutShared: isOutShared
        )
        viewModel.loadAvailableActions()
        let actions = viewModel.availableActions.compactMap { $0.type }
        XCTAssertEqual(actions, expectedActions, "Actions for \(backupType) backup [Exported: \(isExported), Outshared: \(isOutShared)] are incorrect")
    }
    
    private func makeSUT(
        backupType: BackupTypeEntity = .invalid,
        isExported: Bool = false,
        isOutShared: Bool = false,
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
            handle: 1,
            isOutShare: isOutShared,
            isExported: isExported
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
            assets: assets
        )
        
        trackForMemoryLeaks(on: sut, file: file, line: line)
        return sut
    }
}
