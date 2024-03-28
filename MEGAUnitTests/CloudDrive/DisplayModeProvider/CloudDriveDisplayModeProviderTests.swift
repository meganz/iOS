@testable import MEGA
import XCTest

final class CloudDriveDisplayModeProviderTests: XCTestCase {
    func testDisplayMode_withAllValidModes_shouldReturnTheModes() {
        // given
        let inputModes: [DisplayMode] = [
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

        // when
        let providers = inputModes.map { mode in CloudDriveDisplayModeProvider { mode } }
        let outputModes = providers.compactMap { $0.displayMode() }
    
        // then
        XCTAssertEqual(inputModes, outputModes)
    }
    
    func testDisplayMode_withNil_shouldReturnNil() {
        // given
        // when
        let provider = CloudDriveDisplayModeProvider { nil }
    
        // then
        XCTAssertNil(provider.displayMode())
    }
}
