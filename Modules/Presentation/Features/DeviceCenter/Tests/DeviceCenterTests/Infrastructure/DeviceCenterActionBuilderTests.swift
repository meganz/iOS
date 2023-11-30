@testable import DeviceCenter
import MEGADomain
import MEGADomainMock
import XCTest

final class DeviceCenterActionBuilderTests: XCTestCase {
    
    func testBuildActions_forUploadBackupExportedNotOutsharedNode_expectedActionsReturned() {
        let sutActions = makeSUT(
            type: .backup(
                BackupEntity(
                    type: .backupUpload
                )
            ),
            isOutShare: false,
            isExported: true
        )
        
        let expectedActions: [DeviceCenterAction] = [
            .infoAction(),
            .offlineAction(),
            .manageLinkAction(),
            .removeLinkAction(),
            .shareFolderAction(),
            .copyAction()
        ]
        
        XCTAssertEqual(
            sutActions.map(\.title),
            expectedActions.map(\.title),
            "The expected actions should be returned for backup upload with an exported not outshared node."
        )
    }
    
    func testBuildActions_forUploadBackupNotExportedNotOutsharedNode_expectedActionsReturned() {
        let sutActions = makeSUT(
            type: .backup(
                BackupEntity(
                    type: .backupUpload
                )
            ),
            isOutShare: false,
            isExported: false
        )
        
        let expectedActions: [DeviceCenterAction] = [
            .infoAction(),
            .offlineAction(),
            .shareLinkAction(),
            .shareFolderAction(),
            .copyAction()
        ]
        
        XCTAssertEqual(
            sutActions.map(\.title),
            expectedActions.map(\.title),
            "The expected actions should be returned for backup upload with a not exported and not outshared node."
        )
    }
    
    func testBuildActions_forUploadBackupExportedOutsharedNode_expectedActionsReturned() {
        let sutActions = makeSUT(
            type: .backup(
                BackupEntity(
                    type: .backupUpload
                )
            ),
            isOutShare: true,
            isExported: true
        )
        
        let expectedActions: [DeviceCenterAction] = [
            .infoAction(),
            .offlineAction(),
            .manageLinkAction(),
            .removeLinkAction(),
            .manageFolderAction(),
            .copyAction()
        ]
        
        XCTAssertEqual(
            sutActions.map(\.title),
            expectedActions.map(\.title),
            "The expected actions should be returned for backup upload with an exported and outshared node."
        )
    }
    
    func testBuild_forBackupTypeWithNilNode_emptyArrayReturned() {
        let backup = BackupEntity(type: .backupUpload)
        
        let actions = DeviceCenterActionBuilder()
            .setActionType(.backup(backup))
            .build()
        
        XCTAssertTrue(actions.isEmpty, "An empty array should be returned when the node is nil.")
    }
    
    func testBuild_forDeviceTypeNotImplemented_emptyArrayReturned() {
        
        let sutActions = makeSUT(
            type: .device(
                DeviceEntity(
                    id: "",
                    name: ""
                )
            ),
            isOutShare: true,
            isExported: true
        )
        
        XCTAssertTrue(sutActions.isEmpty, "An empty array should be returned for device type, as it's not implemented yet.")
    }
    
    func testBuild_forUnknownType_emptyArrayReturned() {
        
        let sutActions = makeSUT(
            type: .unknown,
            isOutShare: true,
            isExported: true
        )
        
        XCTAssertTrue(sutActions.isEmpty, "An empty array should be returned for an unknown type.")
    }
    
    private func makeSUT(
        type: DeviceCenterItemType,
        isOutShare: Bool,
        isExported: Bool
    ) -> [DeviceCenterAction] {
        
        let node = NodeEntity(
            isOutShare: isOutShare,
            isExported: isExported
        )
        
        return DeviceCenterActionBuilder()
            .setActionType(type)
            .setNode(node)
            .build()
    }
}
