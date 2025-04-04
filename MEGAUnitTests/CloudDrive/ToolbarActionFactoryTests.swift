@testable import MEGA
import MEGAAppPresentation
import MEGAAppPresentationMock
import MEGAAppSDKRepoMock
import MEGADomain
import MEGADomainMock
import MEGATest
import XCTest

final class ToolbarActionFactoryTests: XCTestCase {
    
    func testFactoryForAccessFull_productsCorrectActions() {
        let factory = ToolbarActionFactory()
        let actions = factory.buildActions(
            accessType: .full,
            isBackupNode: false,
            displayMode: .cloudDrive
        )
        XCTAssertEqual(actions, [
            .download,
            .copy,
            .move,
            .delete
        ])
    }
    
    func testFactoryForAccessRead_NotBackup_productsCorrectActions() {
        let factory = ToolbarActionFactory()
        let actions = factory.buildActions(
            accessType: .read,
            isBackupNode: false,
            displayMode: .cloudDrive
        )
        XCTAssertEqual(actions, [
            .download,
            .copy
        ])
    }
    
    func testFactoryForAccessRead_Backup_productsCorrectActions() {
        let factory = ToolbarActionFactory()
        let actions = factory.buildActions(
            accessType: .read,
            isBackupNode: true,
            displayMode: .cloudDrive
        )
        XCTAssertEqual(actions, [
            .download,
            .shareLink,
            .actions
        ])
    }
    
    func testFactoryForAccessOwner_CloudDrive_productsCorrectActions() {
        let factory = ToolbarActionFactory()
        let actions = factory.buildActions(
            accessType: .owner,
            isBackupNode: false,
            displayMode: .cloudDrive
        )
        XCTAssertEqual(actions, [
            .download,
            .shareLink,
            .move,
            .delete,
            .actions
        ])
    }
    
    func testFactoryForAccessOwner_RubbishBin_productsCorrectActions() {
        let factory = ToolbarActionFactory()
        let actions = factory.buildActions(
            accessType: .owner,
            isBackupNode: false,
            displayMode: .rubbishBin
        )
        XCTAssertEqual(actions, [
            .restore,
            .delete
        ])
    }
    
    func testFactoryForAccessOwner_OtherDisplay_returnsNoActions() {
        let factory = ToolbarActionFactory()
        let actions = factory.buildActions(
            accessType: .owner,
            isBackupNode: false,
            displayMode: .unknown
        )
        XCTAssertEqual(actions, [])
    }
    
    func testFactoryForUnknownAccessMode_returnsNoActions() {
        let factory = ToolbarActionFactory()
        let actions = factory.buildActions(
            accessType: .unknown,
            isBackupNode: false,
            displayMode: .unknown
        )
        XCTAssertEqual(actions, [])
    }
    
    func testFactoryForAccessOwner_Backups_productsCorrectActions() {
        let factory = ToolbarActionFactory()
        let actions = factory.buildActions(
            accessType: .owner,
            isBackupNode: false,
            displayMode: .backup
        )
        XCTAssertEqual(actions, [
            .download,
            .shareLink,
            .actions
        ])
    }
}
