@testable import DeviceCenter
import MEGADomain
import MEGADomainMock
import XCTest

final class DeviceCenterActionBuilderTests: XCTestCase {
    func testBuildActions_forUploadBackupExportedNotOutsharedNode_expectedActionsReturned() {
        testDeviceCanterActions(
            type: .backup(
                BackupEntity(
                    type: .backupUpload
                )
            ),
            isExported: true,
            expectedActions: [
                .infoAction(),
                .downloadAction(),
                .manageLinkAction(),
                .removeLinkAction(),
                .shareFolderAction(),
                .copyAction()
            ],
            message: "The expected actions should be returned for backup upload with an exported not outshared node."
        )
    }
    
    func testBuildActions_forUploadBackupNotExportedNotOutsharedNode_expectedActionsReturned() {
        testDeviceCanterActions(
            type: .backup(
                BackupEntity(
                    type: .backupUpload
                )
            ),
            expectedActions: [
                .infoAction(),
                .downloadAction(),
                .shareLinkAction(),
                .shareFolderAction(),
                .copyAction()
            ],
            message: "The expected actions should be returned for backup upload with a not exported and not outshared node."
        )
    }
    
    func testBuildActions_forUploadBackupExportedOutsharedNode_expectedActionsReturned() {
        testDeviceCanterActions(
            type: .backup(
                BackupEntity(
                    type: .backupUpload
                )
            ),
            isOutShare: true,
            isExported: true,
            expectedActions: [
                .infoAction(),
                .downloadAction(),
                .manageLinkAction(),
                .removeLinkAction(),
                .manageFolderAction(),
                .copyAction()
            ],
            message: "The expected actions should be returned for backup upload with an exported and outshared node."
        )
    }
    
    func testBuild_forBackupTypeWithNilNode_emptyArrayReturned() {
        let backup = BackupEntity(type: .backupUpload)
        
        let actions = DeviceCenterActionBuilder()
            .setActionType(.backup(backup))
            .build()
        
        XCTAssertTrue(actions.isEmpty, "An empty array should be returned when the node is nil.")
    }
    
    func testBuildActions_forCUBackupFavouritedExportedOutsharedNode_expectedActionsReturned() {
        testDeviceCanterActions(
            type: .backup(
                BackupEntity(
                    type: .cameraUpload
                )
            ),
            isFavorite: true,
            isOutShare: true,
            isExported: true,
            expectedActions: [
                .infoAction(),
                .favouriteAction(isFavourite: false),
                .labelAction(label: .unknown),
                .downloadAction(),
                .manageLinkAction(),
                .removeLinkAction(),
                .manageFolderAction(),
                .moveAction(),
                .copyAction(),
                .moveToTheRubbishBinAction()
            ],
            message: "The expected actions should be returned for CU backup with a favourited and exported node."
        )
    }
    
    func testBuildActions_forCUBackupNonFavouritedNonExportedButOutsharedNode_expectedActionsReturned() {
        testDeviceCanterActions(
            type: .backup(
                BackupEntity(
                    type: .cameraUpload
                )
            ),
            isOutShare: true,
            expectedActions: [
                .infoAction(),
                .favouriteAction(isFavourite: false),
                .labelAction(label: .unknown),
                .downloadAction(),
                .shareLinkAction(),
                .manageFolderAction(),
                .moveAction(),
                .copyAction(),
                .moveToTheRubbishBinAction()
            ],
            message: "The expected actions should be returned for CU backup with a outshared node."
        )
    }

    func testBuildActions_forCUBackupNonFavouritedNonExportedNonOutsharedNode_expectedActionsReturned() {
        testDeviceCanterActions(
            type: .backup(
                BackupEntity(
                    type: .cameraUpload
                )
            ),
            expectedActions: [
                .infoAction(),
                .favouriteAction(isFavourite: false),
                .labelAction(label: .unknown),
                .downloadAction(),
                .shareLinkAction(),
                .shareFolderAction(),
                .moveAction(),
                .copyAction(),
                .moveToTheRubbishBinAction()
            ],
            message: "The expected actions should be returned for CU backup with a non favourited, non exported and non outshared node."
        )
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
    
    private func testDeviceCanterActions(
        type: DeviceCenterItemType,
        isFavorite: Bool = false,
        isOutShare: Bool = false,
        isExported: Bool = false,
        expectedActions: [DeviceCenterAction],
        message: String
    ) {
        let sutActions = makeSUT(
            type: type,
            isFavorite: isFavorite,
            isOutShare: isOutShare,
            isExported: isExported
        )

        XCTAssertEqual(
            sutActions.map(\.title),
            expectedActions.map(\.title),
            message
        )
    }
    
    private func makeSUT(
        type: DeviceCenterItemType,
        isFavorite: Bool = false,
        isOutShare: Bool = false,
        isExported: Bool = false
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
