@testable import MEGA
import XCTest

/// Pins the offline policy for the two action types that cannot leave the app target (IOS-12228).
/// The shared context-menu enums are pinned by MEGAAppPresentation's
/// `ActionsRequiringConnectionTests`, the floating add button's by CloudDrive's
/// `FloatingActionEntityRequiresConnectionTests`.
final class AppActionsRequiringConnectionTests: XCTestCase {

    func testBottomToolbarAction_requiringConnection() {
        assertRequiresConnection([.download, .shareLink, .move, .copy, .delete, .restore] as [BottomToolbarAction])
        assertDoesNotRequireConnection([.actions] as [BottomToolbarAction])
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
    ) where T: AppRequiresConnectionReporting {
        for action in actions {
            XCTAssertTrue(action.requiresConnection, "\(action) should require a connection", file: file, line: line)
        }
    }

    private func assertDoesNotRequireConnection<T>(
        _ actions: [T],
        file: StaticString = #filePath,
        line: UInt = #line
    ) where T: AppRequiresConnectionReporting {
        for action in actions {
            XCTAssertFalse(action.requiresConnection, "\(action) should stay available offline", file: file, line: line)
        }
    }
}

/// Lets the assertions above work over every action enum without repeating them per type.
protocol AppRequiresConnectionReporting {
    var requiresConnection: Bool { get }
}

extension BottomToolbarAction: AppRequiresConnectionReporting {}
extension MegaNodeActionType: AppRequiresConnectionReporting {}
