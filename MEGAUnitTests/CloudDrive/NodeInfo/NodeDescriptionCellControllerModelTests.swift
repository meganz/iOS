@testable import MEGA
import MEGADomain
import MEGADomainMock
import MEGAL10n
import MEGAPresentation
import MEGAPresentationMock
import MEGATest
import XCTest

@MainActor
final class NodeDescriptionCellControllerModelTests: XCTestCase {

    var readOnlyAccessNodeTypes: [NodeAccessTypeEntity] {
        [.readWrite, .read, .unknown]
    }

    var fullAccessNodeTypes: [NodeAccessTypeEntity] {
        [.owner, .full]
    }
    
    var saveStates: [NodeDescriptionCellControllerModel.SavedState] {
        [.added, .updated, .removed, .error]
    }

    func testHasReadonlyAccess_whenNodeIsInRubbishBin_shouldReturnTrue() {
        let sut = makeSUT(isNodeInRubbishBin: true)
        XCTAssertTrue(sut.hasReadOnlyAccess)
    }
    
    func testHasReadonlyAccess_whenNodeIsBackupsNode_shouldReturnTrue() {
        let sut = makeSUT(isBackupsNode: true)
        XCTAssertTrue(sut.hasReadOnlyAccess)
    }
    
    func testHasReadonlyAccess_whenNodeIsBackupsRootNode_shouldReturnTrue() {
        let sut = makeSUT(isBackupsRootNode: true)
        XCTAssertTrue(sut.hasReadOnlyAccess)
    }

    func testHeader_whenInvoked_shouldMatch() {
        let sut = makeSUT()
        XCTAssertEqual(sut.header, Strings.Localizable.CloudDrive.NodeInfo.NodeDescription.header)
    }

    func testFooter_withAccessToUpdateNodeDescription_shouldReturnNil() {
        fullAccessNodeTypes.forEach {
            let sut = makeSUT(accessType: $0)
            XCTAssertFalse(sut.hasReadOnlyAccess)
            XCTAssertNil(sut.footer)
        }
    }

    func testFooter_withNoAccessToUpdateNodeDescription_shouldReturnFooterText() {
        readOnlyAccessNodeTypes.forEach {
            let sut = makeSUT(accessType: $0)
            XCTAssertTrue(sut.hasReadOnlyAccess)
            XCTAssertEqual(sut.footer, Strings.Localizable.CloudDrive.NodeInfo.NodeDescription.readonly)
        }
    }

    func testFooter_withNodeInRubbishBin_shouldReturnFooterText() {
        let sut = makeSUT(isNodeInRubbishBin: true)
        XCTAssertTrue(sut.hasReadOnlyAccess)
        XCTAssertEqual(sut.footer, Strings.Localizable.CloudDrive.NodeInfo.NodeDescription.readonly)
    }

    func testFooter_withNodeIsBackupsNode_shouldReturnFooterText() {
        let sut = makeSUT(isBackupsNode: true)
        XCTAssertTrue(sut.hasReadOnlyAccess)
        XCTAssertEqual(sut.footer, Strings.Localizable.CloudDrive.NodeInfo.NodeDescription.readonly)
    }

    func testFooter_withNodeABackupsRootNode_shouldReturnFooterText() {
        let sut = makeSUT(isBackupsRootNode: true)
        XCTAssertTrue(sut.hasReadOnlyAccess)
        XCTAssertEqual(sut.footer, Strings.Localizable.CloudDrive.NodeInfo.NodeDescription.readonly)
    }

    func testHasPendingChanges_whenInitInvoked_shouldReturnFalse() {
        let sut = makeSUT()
        XCTAssertFalse(sut.hasPendingChanges())
    }

    func testHasPendingChanges_whenTextChanged_shouldReturnTrue() {
        let sut = makeSUT()
        sut.cellViewModel.descriptionUpdated("updated description")
        XCTAssertTrue(sut.hasPendingChanges())
    }

    func testSavePendingChanges_whenInitInvoked_shouldReturnNil() async {
        let sut = makeSUT()
        let result = await sut.savePendingChanges()
        XCTAssertNil(result)
    }

    func testSavePendingChanges_whenNoPendingChanges_shouldReturnNil() async {
        let sut = makeSUT(description: "description")
        sut.cellViewModel.descriptionUpdated("description")
        let result = await sut.savePendingChanges()
        XCTAssertNil(result)
    }

    func testSavePendingChanges_whenError_shouldReturnErrorAndCallDescriptionSavedWithError() async {
        let sut = makeSUT(nodeDescriptionResult: .failure(NSError(domain: "", code: 0))) {
            XCTAssertEqual($0, .error)
        }
        sut.cellViewModel.descriptionUpdated("description")
        let result = await sut.savePendingChanges()
        XCTAssertEqual(result, .error)
    }

    func testSavePendingChanges_whenAdded_shouldReturnAdded() async {
        let sut = makeSUT(description: nil)
        sut.cellViewModel.descriptionUpdated("description")
        let result = await sut.savePendingChanges()
        XCTAssertEqual(result, .added)
    }

    func testSavePendingChanges_whenUpdated_shouldReturnUpdated() async {
        let sut = makeSUT(description: "description")
        sut.cellViewModel.descriptionUpdated("updated description")
        let result = await sut.savePendingChanges()
        XCTAssertEqual(result, .updated)
    }

    func testSavePendingChanges_whenRemoved_shouldReturnRemoved() async {
        let sut = makeSUT(description: "description")
        sut.cellViewModel.descriptionUpdated("")
        let result = await sut.savePendingChanges()
        XCTAssertEqual(result, .removed)
    }
    
    func testFooterViewModel_whenDescriptionUpdated_withReadOnlyAccess_shouldShowLeadingTextAndHideTrailingTextAndNotScrollToCell() {
        let sut = makeSUT(description: "", accessType: .read, maxCharactersAllowed: 20)
        var scrollToCellTriggered = false
        sut.scrollToCell = {
            scrollToCellTriggered = true
        }
        sut.cellViewModel.descriptionUpdated("updated")
        XCTAssertEqual(sut.footerViewModel.leadingText, "Read-only")
        XCTAssertEqual(sut.footerViewModel.trailingText, nil)
        XCTAssertFalse(scrollToCellTriggered)
    }
    
    func testFooterViewModel_whenDescriptionUpdated_withReadWriteAccess_shouldShowLeadingTextAndHideTrailingTextAndNotScrollToCell() {
        let sut = makeSUT(description: "", accessType: .readWrite, maxCharactersAllowed: 20)
        var scrollToCellTriggered = false
        sut.scrollToCell = {
            scrollToCellTriggered = true
        }
        sut.cellViewModel.descriptionUpdated("updated")
        XCTAssertEqual(sut.footerViewModel.leadingText, "Read-only")
        XCTAssertEqual(sut.footerViewModel.trailingText, nil)
        XCTAssertFalse(scrollToCellTriggered)
    }

    func testFooterViewModel_whenDescriptionUpdated_withOwnerAccess_whileEditing_shouldMatchTheTrailingTextAndScrollToCell() {
        let sut = makeSUT(description: "", accessType: .owner, maxCharactersAllowed: 20)
        var scrollToCellTriggered = false
        sut.scrollToCell = {
            scrollToCellTriggered = true
        }
        sut.cellViewModel.isTextViewFocused(true)
        sut.cellViewModel.descriptionUpdated("description added")
        XCTAssertEqual(sut.footerViewModel.trailingText, "17/20")
        XCTAssertTrue(scrollToCellTriggered)
    }
    
    func testFooterViewModel_whenDescriptionUpdated_whileEditing_shouldMatchTheTrailingTextAndScrollToCell() {
        let sut = makeSUT(description: "", accessType: .full, maxCharactersAllowed: 20)
        var scrollToCellTriggered = false
        sut.scrollToCell = {
            scrollToCellTriggered = true
        }
        sut.cellViewModel.isTextViewFocused(true)
        sut.cellViewModel.descriptionUpdated("description added")
        XCTAssertEqual(sut.footerViewModel.trailingText, "17/20")
        XCTAssertTrue(scrollToCellTriggered)
    }

    func testFooterViewModel_whenDoneButtonTappedAndDescriptionAdded_shouldSaveDescription() async {
        await assertFooterViewModel(
            initialDescription: "",
            updatedDescription: "description",
            expectedResult: .added
        )
    }

    func testFooterViewModel_whenDoneButtonTappedAndDescriptionRemoved_shouldSaveDescription() async {
        await assertFooterViewModel(
            initialDescription: "description",
            updatedDescription: "",
            expectedResult: .removed
        )
    }

    func testFooterViewModel_whenDoneButtonTappedAndDescriptionUpdated_shouldSaveDescription() async {
        await assertFooterViewModel(
            initialDescription: "description",
            updatedDescription: "description updated",
            expectedResult: .updated
        )
    }

    func testIsTextViewFocused_whenChangedFromNotFocusedToFocused_shouldShowTrailingText() {
        let sut = makeSUT(description: "description added", maxCharactersAllowed: 20)
        XCTAssertNil(sut.footerViewModel.trailingText)
        sut.cellViewModel.isTextViewFocused(true)
        XCTAssertEqual(sut.footerViewModel.trailingText, "17/20")
    }

    func testIsTextViewFocused_whenChangedFromFocusedToNotFocused_shouldShowTrailingText() {
        let sut = makeSUT(description: "description added", maxCharactersAllowed: 20)
        sut.cellViewModel.isTextViewFocused(true)
        XCTAssertEqual(sut.footerViewModel.trailingText, "17/20")
        sut.cellViewModel.isTextViewFocused(false)
        XCTAssertNil(sut.footerViewModel.trailingText)
    }
    
    func testUpdateDescription_whenDescriptionIsUpdated_shouldChangeDescription() {
        let sut = makeSUT()
        let node = NodeEntity(description: "testUpdateDescription")
        sut.cellViewModel.isTextViewFocused(true)
        sut.updateDescription(with: node)
        XCTAssertEqual(sut.description.content, "testUpdateDescription")
        
        XCTAssertEqual(sut.footerViewModel.trailingText, "21/300")
        XCTAssertNil(sut.footerViewModel.leadingText)
    }
    
    func testSaveState_whenGetlocalizedString_shouldMatchLocalizedValue() {
        let outputStrings = saveStates.map(\.localizedString)
        let expectedStrings = [
            Strings.Localizable.CloudDrive.NodeInfo.NodeDescription.SavedState.descriptionAdded,
            Strings.Localizable.CloudDrive.NodeInfo.NodeDescription.SavedState.descriptionUpdated,
            Strings.Localizable.CloudDrive.NodeInfo.NodeDescription.SavedState.descriptionRemoved,
            Strings.Localizable.CloudDrive.NodeInfo.NodeDescription.SavedState.error
        ]
        XCTAssertEqual(outputStrings, expectedStrings)
    }
    
    func testAnalyticsTracking_whenDescriptionAdded_shouldTrackCorrectEvent() async {
        let exp = expectation(description: "wait for description added")
        
        let tracker = MockTracker()
        let sut = makeSUT(description: nil, tracker: tracker) { _ in
            exp.fulfill()
        }

        sut.cellViewModel.descriptionUpdated("add")
        sut.cellViewModel.saveDescription("add")
        await fulfillment(of: [exp], timeout: 1.0)
        
        XCTAssertEqual(tracker.trackedEventIdentifiers.map(\.eventName), ["NodeInfoDescriptionAddedMessageDisplayed"])
    }
    
    func testAnalyticsTracking_whenDescriptionUpdated_shouldTrackCorrectEvent() async {
        let exp = expectation(description: "wait for description added")
        
        let tracker = MockTracker()
        let sut = makeSUT(description: "Intial", tracker: tracker) { _ in
            exp.fulfill()
        }

        sut.cellViewModel.descriptionUpdated("Updated")
        sut.cellViewModel.saveDescription("Updated")
        await fulfillment(of: [exp], timeout: 1.0)
        
        XCTAssertEqual(tracker.trackedEventIdentifiers.map(\.eventName), ["NodeInfoDescriptionUpdatedMessageDisplayed"])
    }
    
    func testAnalyticsTracking_whenDescriptionRemoved_shouldTrackCorrectEvent() async {
        let exp = expectation(description: "wait for description added")
        
        let tracker = MockTracker()
        let sut = makeSUT(description: "Intial", tracker: tracker) { _ in
            exp.fulfill()
        }

        sut.cellViewModel.descriptionUpdated("")
        sut.cellViewModel.saveDescription("")
        await fulfillment(of: [exp], timeout: 1.0)
        
        XCTAssertEqual(tracker.trackedEventIdentifiers.map(\.eventName), ["NodeInfoDescriptionRemovedMessageDisplayed"])
    }
    
    func testAnalyticsTracking_whenFailedToSaveDescription_shouldTrackCorrectEvent() async {
        let exp = expectation(description: "wait for description added")
        
        let tracker = MockTracker()
        let sut = makeSUT(description: "Intial", tracker: tracker, nodeDescriptionResult: .failure(CancellationError())
        ) { _ in
            exp.fulfill()
        }

        sut.cellViewModel.descriptionUpdated("")
        sut.cellViewModel.saveDescription("")
        await fulfillment(of: [exp], timeout: 1.0)
        
        XCTAssertEqual(tracker.trackedEventIdentifiers.map(\.eventName), [])
    }

    // MARK: - Helpers

    private func makeSUT(
        description: String? = "any description",
        accessType: NodeAccessTypeEntity = .owner,
        isNodeInRubbishBin: Bool = false,
        isBackupsNode: Bool = false,
        isBackupsRootNode: Bool = false,
        maxCharactersAllowed: Int = 300,
        tracker: some AnalyticsTracking = MockTracker(),
        nodeDescriptionResult: Result<NodeEntity, any Error> = .success(NodeEntity()),
        descriptionSaved: @escaping (NodeDescriptionCellControllerModel.SavedState) -> Void = { _ in },
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> NodeDescriptionCellControllerModel {
        let nodeUseCase = MockNodeDataUseCase(
            nodeAccessLevelVariable: accessType,
            isNodeInRubbishBin: { _ in isNodeInRubbishBin }
        )
        let backupUseCase = MockBackupsUseCase(
            isBackupsNode: isBackupsNode,
            isBackupsRootNode: isBackupsRootNode
        )
        let sut = NodeDescriptionCellControllerModel(
            node: NodeEntity(description: description),
            nodeUseCase: nodeUseCase,
            backupUseCase: backupUseCase,
            nodeDescriptionUseCase: MockNodeDescriptionUseCase(result: nodeDescriptionResult),
            maxCharactersAllowed: maxCharactersAllowed,
            tracker: tracker,
            refreshUI: { block in block() },
            descriptionSaved: descriptionSaved
        )
        trackForMemoryLeaks(on: sut)
        return sut
    }

    private func assertFooterViewModel(
        initialDescription: String,
        updatedDescription: String,
        expectedResult: NodeDescriptionCellControllerModel.SavedState
    ) async {
        let exp = expectation(description: "wait to save description")
        let sut = makeSUT(description: initialDescription) {
            XCTAssertEqual($0, expectedResult)
            exp.fulfill()
        }

        sut.cellViewModel.descriptionUpdated(updatedDescription)
        sut.cellViewModel.saveDescription(updatedDescription)
        await fulfillment(of: [exp], timeout: 1.0)
    }
    
}

extension NodeAccessTypeEntity: CustomStringConvertible {
    public var description: String {
        switch self {
        case .owner: return "Owner"
        case .full: return "Full access"
        case .readWrite: return "Read write access"
        case .read: return "Read only access"
        case .unknown: return "Access Unkown"
        }
    }
}
