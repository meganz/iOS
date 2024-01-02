@testable import MEGA
import XCTest

final class DisplayModeTests: XCTestCase {
    func testCarriedOverDisplayMode_backupsCase_isCarriedOver() {
        let displayMode = DisplayMode.backup
        XCTAssertEqual(displayMode.carriedOverDisplayMode, .backup)
    }
    
    func testCarriedOverDisplayMode_rubbishBinCase_isCarriedOver() {
        let displayMode = DisplayMode.rubbishBin
        XCTAssertEqual(displayMode.carriedOverDisplayMode, .rubbishBin)
    }
    
    func testCarriedOverDisplayMode_OtherCases_notCarriedOver() {
        let allDisplayModes: [DisplayMode] = [
            .unknown,
            .cloudDrive,
            .rubbishBin,
            .sharedItem,
            .nodeInfo,
            .nodeVersions,
            .folderLink,
            .fileLink,
            .nodeInsideFolderLink,
            .recents,
            .publicLinkTransfers,
            .transfers,
            .transfersFailed,
            .chatAttachment,
            .chatSharedFiles,
            .previewDocument,
            .textEditor,
            .backup,
            .mediaDiscovery,
            .photosFavouriteAlbum,
            .photosAlbum,
            .photosTimeline,
            .previewPdfPage
            ]
        let filteredOut = allDisplayModes.filter {
            $0 != .rubbishBin && $0 != .backup
        }
        
        filteredOut.forEach { mode in
            XCTAssertNil(mode.carriedOverDisplayMode)
        }
        
    }
}
