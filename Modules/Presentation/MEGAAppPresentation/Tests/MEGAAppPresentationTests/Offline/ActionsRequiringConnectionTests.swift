import MEGAAppPresentation
import MEGADomain
import XCTest

/// Pins the offline policy for the shared context-menu actions (IOS-12228). The action types that
/// cannot be seen from here carry the same property in the app target, pinned by
/// `AppActionsRequiringConnectionTests`.
final class ActionsRequiringConnectionTests: XCTestCase {

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

    func testUploadAddActionEntity_allRequireConnection() {
        XCTAssertTrue(UploadAddActionEntity.allCases.allSatisfy(\.requiresConnection))
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

extension QuickActionEntity: RequiresConnectionReporting {}
extension DisplayActionEntity: RequiresConnectionReporting {}
extension RubbishBinActionEntity: RequiresConnectionReporting {}
extension UploadAddActionEntity: RequiresConnectionReporting {}
