import CloudDrive
@testable import MEGA
import MEGADomain
import XCTest

/// Pins the offline policy: which Cloud Drive actions need a connection (IOS-12228).
final class ActionsRequiringConnectionTests: XCTestCase {

    func testBottomToolbarAction_requiringConnection() {
        assertRequiresConnection([.download, .shareLink, .move, .copy, .delete, .restore] as [BottomToolbarAction])
        assertDoesNotRequireConnection([.actions] as [BottomToolbarAction])
    }

    func testQuickActionEntity_requiringConnection() {
        assertRequiresConnection([
            .download, .shareLink, .manageLink, .removeLink, .shareFolder, .manageFolder,
            .rename, .copy, .removeSharing, .leaveSharing, .sendToChat, .saveToPhotos,
            .hide, .unhide, .dispute
        ] as [QuickActionEntity])
        assertDoesNotRequireConnection([.info, .settings] as [QuickActionEntity])
    }

    func testDisplayActionEntity_requiringConnection() {
        // Both are remote writes: emptying the rubbish bin, and creating a video playlist (a Set)
        assertRequiresConnection([.clearRubbishBin, .newPlaylist] as [DisplayActionEntity])
        assertDoesNotRequireConnection([
            .select, .mediaDiscovery, .thumbnailView, .listView, .sort, .filter, .filterActive,
            .locationFilter, .durationFilter, .mediaTypeFilter, .mediaLocationFilter
        ] as [DisplayActionEntity])
    }

    func testRubbishBinActionEntity_requiringConnection() {
        assertRequiresConnection([.restore, .remove] as [RubbishBinActionEntity])
        assertDoesNotRequireConnection([.info, .versions] as [RubbishBinActionEntity])
    }

    func testUploadAndCreationActions_allRequireConnection() {
        XCTAssertTrue(FloatingActionEntity.allCases.allSatisfy(\.requiresConnection))
        XCTAssertTrue(UploadAddActionEntity.allCases.allSatisfy(\.requiresConnection))
    }

    func testMegaNodeActionType_readOnlyActionsStayAvailable() {
        assertDoesNotRequireConnection([
            .info, .viewVersions, .select, .search, .list, .thumbnail, .sort, .mediaDiscovery,
            .pdfPageView, .pdfThumbnailView, .viewInFolder, .showInLocation, .clear, .verifyContact
        ] as [MegaNodeActionType])
    }

    func testMegaNodeActionType_mutatingAndTransferActionsRequireConnection() {
        assertRequiresConnection([
            .download, .exportFile, .copy, .move, .favourite, .label, .leaveSharing, .rename,
            .removeLink, .moveToRubbishBin, .remove, .removeSharing, .import, .revertVersion,
            .restore, .saveToPhotos, .manageShare, .shareFolder, .manageLink, .shareLink,
            .sendToChat, .editTextFile, .disputeTakedown, .restoreBackup, .hide, .unhide,
            .addTo, .addToAlbum
        ] as [MegaNodeActionType])
    }

    // MARK: - Helpers

    private func assertRequiresConnection<T>(
        _ actions: [T],
        file: StaticString = #filePath,
        line: UInt = #line
    ) where T: RequiresConnectionReporting {
        for action in actions {
            XCTAssertTrue(action.requiresConnection, "\(action) should require a connection", file: file, line: line)
        }
    }

    private func assertDoesNotRequireConnection<T>(
        _ actions: [T],
        file: StaticString = #filePath,
        line: UInt = #line
    ) where T: RequiresConnectionReporting {
        for action in actions {
            XCTAssertFalse(action.requiresConnection, "\(action) should stay available offline", file: file, line: line)
        }
    }
}

/// Lets the assertions above work over every action enum without repeating them per type.
protocol RequiresConnectionReporting {
    var requiresConnection: Bool { get }
}

extension BottomToolbarAction: RequiresConnectionReporting {}
extension QuickActionEntity: RequiresConnectionReporting {}
extension DisplayActionEntity: RequiresConnectionReporting {}
extension RubbishBinActionEntity: RequiresConnectionReporting {}
extension FloatingActionEntity: RequiresConnectionReporting {}
extension UploadAddActionEntity: RequiresConnectionReporting {}
extension MegaNodeActionType: RequiresConnectionReporting {}
