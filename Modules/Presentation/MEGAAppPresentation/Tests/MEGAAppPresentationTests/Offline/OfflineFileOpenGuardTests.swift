import MEGAAppPresentation
import MEGADomain
import MEGADomainMock
import XCTest

final class OfflineFileOpenGuardTests: XCTestCase {

    private let file = NodeEntity(name: "report.pdf", handle: 1, isFile: true)
    private let image = NodeEntity(name: "photo.jpg", handle: 2, isFile: true)
    private let folder = NodeEntity(name: "Documents", handle: 3, isFile: false, isFolder: true)

    private func makeSUT(
        isNewOfflineModeEnabled: Bool = true,
        isConnected: Bool = false,
        isDownloaded: Bool = false,
        hasCachedPreview: Bool = false
    ) -> OfflineFileOpenGuard {
        OfflineFileOpenGuard(
            isNewOfflineModeEnabled: isNewOfflineModeEnabled,
            networkMonitorUseCase: MockNetworkMonitorUseCase(connected: isConnected),
            nodeUseCase: MockNodeDataUseCase(downloaded: isDownloaded),
            thumbnailUseCase: MockThumbnailUseCase(hasCachedPreviewOrOriginal: hasCachedPreview)
        )
    }

    func testShouldBlockOpening_offlineFileWithoutLocalCopy_blocks() async {
        let shouldBlock = await makeSUT().shouldBlockOpening(file)
        XCTAssertTrue(shouldBlock)
    }

    func testShouldBlockOpening_whenNewOfflineModeDisabled_doesNotBlock() async {
        let shouldBlock = await makeSUT(isNewOfflineModeEnabled: false).shouldBlockOpening(file)
        XCTAssertFalse(shouldBlock)
    }

    func testShouldBlockOpening_whenConnected_doesNotBlock() async {
        let shouldBlock = await makeSUT(isConnected: true).shouldBlockOpening(file)
        XCTAssertFalse(shouldBlock)
    }

    func testShouldBlockOpening_folder_doesNotBlock() async {
        let shouldBlock = await makeSUT().shouldBlockOpening(folder)
        XCTAssertFalse(shouldBlock)
    }

    func testShouldBlockOpening_downloadedFile_doesNotBlock() async {
        let shouldBlock = await makeSUT(isDownloaded: true).shouldBlockOpening(file)
        XCTAssertFalse(shouldBlock)
    }

    func testShouldBlockOpening_imageWithCachedPreview_doesNotBlock() async {
        let shouldBlock = await makeSUT(hasCachedPreview: true).shouldBlockOpening(image)
        XCTAssertFalse(shouldBlock)
    }

    func testShouldBlockOpening_imageWithoutCachedPreview_blocks() async {
        let shouldBlock = await makeSUT().shouldBlockOpening(image)
        XCTAssertTrue(shouldBlock)
    }

    func testShouldBlockOpening_nonImageFileWithCachedPreview_blocks() async {
        let shouldBlock = await makeSUT(hasCachedPreview: true).shouldBlockOpening(file)
        XCTAssertTrue(shouldBlock)
    }

    func testIsActive_whenOfflineAndNewOfflineModeEnabled_isTrue() {
        XCTAssertTrue(makeSUT().isActive)
    }

    func testIsActive_whenConnected_isFalse() {
        XCTAssertFalse(makeSUT(isConnected: true).isActive)
    }

    func testIsActive_whenNewOfflineModeDisabled_isFalse() {
        XCTAssertFalse(makeSUT(isNewOfflineModeEnabled: false).isActive)
    }
}
