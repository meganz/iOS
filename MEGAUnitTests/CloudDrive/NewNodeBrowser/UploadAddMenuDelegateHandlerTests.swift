@testable import MEGA
import MEGADomain
import XCTest

final class UploadAddMenuDelegateHandlerTests: XCTestCase {

    func testUploadAddMenu_whenNodeIsNil_shouldAvoidCallingAction() {
        assertEmptyActions(with: .node({ nil }))
    }

    func testUploadAddMenu_shouldAvoidCallingActionsForRecentBucket_actionsShouldBeEmpty() {
        assertEmptyActions(with: .recentActionBucket(MEGARecentActionBucket()))
    }

    func testUploadAddMenu_forValidNodeWithChooseFromPhotosAction_shouldCallTheChooseFromPhotoVideoAction() {
        assertValidNode(for: NodeEntity(), action: .chooseFromPhotos, expectedAction: .choosePhotoVideo( NodeEntity()))
    }

    func testUploadAddMenu_forValidNodeWithCaptureAction_shouldCallTheCapturePhotoVideoAction() {
        assertValidNode(for: NodeEntity(), action: .capture, expectedAction: .capturePhotoVideo( NodeEntity()))
    }

    func testUploadAddMenu_forValidNodeWithImportFromAction_shouldCallTheImportFromFilesAction() {
        assertValidNode(for: NodeEntity(), action: .importFrom, expectedAction: .importFromFiles( NodeEntity()))
    }

    func testUploadAddMenu_forValidNodeWithScanDocumentAction_shouldCallTheScanDocumentAction() {
        assertValidNode(for: NodeEntity(), action: .scanDocument, expectedAction: .scanDocument( NodeEntity()))
    }

    func testUploadAddMenu_forValidNodeWithNewFolderAction_shouldCallTheCreateNewFolderAction() {
        assertValidNode(for: NodeEntity(), action: .newFolder, expectedAction: .createNewFolder( NodeEntity()))
    }

    func testUploadAddMenu_forValidNodeWithNewTextFileAction_shouldCallTheCreateTextFileAlertAction() {
        assertValidNode(for: NodeEntity(), action: .newTextFile, expectedAction: .createTextFileAlert( NodeEntity()))
    }

    // MARK: - Private methods.

    typealias SUT = UploadAddMenuDelegateHandler

    private func makeSUT(
        nodeInsertionRouter: some NodeInsertionRouting = MockNodeInsertionRouter(),
        nodeSource: NodeSource,
        file: StaticString = #file,
        line: UInt = #line
    ) -> SUT {
        let sut = SUT(nodeInsertionRouter: nodeInsertionRouter, nodeSource: nodeSource)
        trackForMemoryLeaks(on: sut, file: file, line: line)
        return sut
    }

    private func assertEmptyActions(with nodeSource: NodeSource, file: StaticString = #file, line: UInt = #line) {
        let router = MockNodeInsertionRouter()
        let sut = makeSUT(nodeInsertionRouter: router, nodeSource: .recentActionBucket(MEGARecentActionBucket()))
        sut.uploadAddMenu(didSelect: .chooseFromPhotos)
        sut.uploadAddMenu(didSelect: .capture)
        sut.uploadAddMenu(didSelect: .importFrom)
        sut.uploadAddMenu(didSelect: .scanDocument)
        sut.uploadAddMenu(didSelect: .newFolder)
        sut.uploadAddMenu(didSelect: .newTextFile)
        sut.uploadAddMenu(didSelect: .importFolderLink)
        XCTAssertEqual(router.actions, [], file: file, line: line)
    }

    private func assertValidNode(
        for node: NodeEntity,
        action: UploadAddActionEntity,
        expectedAction: MockNodeInsertionRouter.Action,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        let router = MockNodeInsertionRouter()
        let sut = makeSUT(nodeInsertionRouter: router, nodeSource: .node({ node }))
        sut.uploadAddMenu(didSelect: action)
        router.shouldMatch(expectedAction: expectedAction, file: file, line: line)
    }
}
