@testable import MEGA
import MEGADomain
import MEGADomainMock
import MEGAL10n
import MEGATest
import XCTest

@MainActor
final class NodeDescriptionViewModelTests: XCTestCase {

    var readOnlyAccessNodeTypes: [NodeAccessTypeEntity] {
        [.readWrite, .read, .unknown]
    }

    var fullAccessNodeTypes: [NodeAccessTypeEntity] {
        [.owner, .full]
    }

    func testDescription_whenNodeDescriptionIsAbsentAndNoAccessToUpdateDescription_shouldMatchReadOnlyString() {
        readOnlyAccessNodeTypes.forEach {
            let sut = makeSUT(description: nil, accessType: $0)
            XCTAssertEqual(
                sut.description,
                .placeholder(Strings.Localizable.CloudDrive.NodeInfo.NodeDescription.EmptyText.readOnly)
            )
        }
    }

    func testDescription_whenNodeDescriptionIsEmptyAndNoAccessToUpdateDescription_shouldMatchReadOnlyString() {
        readOnlyAccessNodeTypes.forEach {
            let sut = makeSUT(description: "", accessType: $0)
            XCTAssertEqual(
                sut.description,
                .placeholder(Strings.Localizable.CloudDrive.NodeInfo.NodeDescription.EmptyText.readOnly)
            )
        }
    }

    func testDescription_whenNodeDescriptionIsAbsentAndHasAccessToUpdateDescription_shouldMatchReadOnlyString() {
        fullAccessNodeTypes.forEach {
            let sut = makeSUT(description: nil, accessType: $0)
            XCTAssertEqual(
                sut.description,
                .placeholder(Strings.Localizable.CloudDrive.NodeInfo.NodeDescription.EmptyText.readWrite)
            )
        }
    }

    func testDescription_whenNodeDescriptionIsEmptyAndHasAccessToUpdateDescription_shouldMatchReadOnlyString() {
        fullAccessNodeTypes.forEach {
            let sut = makeSUT(description: "", accessType: $0)
            XCTAssertEqual(
                sut.description,
                .placeholder(Strings.Localizable.CloudDrive.NodeInfo.NodeDescription.EmptyText.readWrite)
            )
        }
    }

    func testDescription_whenNodeDescriptionIsAbsentAndTheNodeIsInRubbishBin_shouldMatchReadOnlyString() {
        let sut = makeSUT(description: nil, isNodeInRubbishBin: true)
        XCTAssertEqual(
            sut.description,
            .placeholder(Strings.Localizable.CloudDrive.NodeInfo.NodeDescription.EmptyText.readOnly)
        )
    }

    func testDescription_whenNodeDescriptionIsEmptyAndTheNodeIsInRubbishBin_shouldMatchReadOnlyString() {
        let sut = makeSUT(description: nil, isNodeInRubbishBin: true)
        XCTAssertEqual(
            sut.description,
            .placeholder(Strings.Localizable.CloudDrive.NodeInfo.NodeDescription.EmptyText.readOnly)
        )
    }

    func testDescription_whenNodeDescriptionIsAbsentAndTheNodeIsBackupsNode_shouldMatchReadOnlyString() {
        let sut = makeSUT(description: nil, isBackupsNode: true)
        XCTAssertEqual(
            sut.description,
            .placeholder(Strings.Localizable.CloudDrive.NodeInfo.NodeDescription.EmptyText.readOnly)
        )
    }

    func testDescription_whenNodeDescriptionIsEmptyAndTheNodeIsBackupsNode_shouldMatchReadOnlyString() {
        let sut = makeSUT(description: nil, isBackupsNode: true)
        XCTAssertEqual(
            sut.description,
            .placeholder(Strings.Localizable.CloudDrive.NodeInfo.NodeDescription.EmptyText.readOnly)
        )
    }

    func testDescription_whenNodeDescriptionIsAbsentAndTheNodeIsBackupsRootNode_shouldMatchReadOnlyString() {
        let sut = makeSUT(description: nil, isBackupsRootNode: true)
        XCTAssertEqual(
            sut.description,
            .placeholder(Strings.Localizable.CloudDrive.NodeInfo.NodeDescription.EmptyText.readOnly)
        )
    }

    func testDescription_whenNodeDescriptionIsEmptyAndTheNodeIsBackupsRootNode_shouldMatchReadOnlyString() {
        let sut = makeSUT(description: nil, isBackupsRootNode: true)
        XCTAssertEqual(
            sut.description,
            .placeholder(Strings.Localizable.CloudDrive.NodeInfo.NodeDescription.EmptyText.readOnly)
        )
    }

    func testDescription_hasNodeDescription_shouldReturnDescription() {
        let description = "any description"
        fullAccessNodeTypes.forEach {
            let sut = makeSUT(description: description, accessType: $0)
            XCTAssertEqual(sut.description, .content(description))
        }
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

    func testFooterViewModel_whenDescriptionUpdated_shouldMatchTheTrailingTextAndScrollToCell() {
        let sut = makeSUT(description: "", maxCharactersAllowed: 20)
        var scrollToCellTriggered = false
        sut.scrollToCell = {
            scrollToCellTriggered = true
        }
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

    // MARK: - Helpers

    private func makeSUT(
        description: String? = "any description",
        accessType: NodeAccessTypeEntity = .owner,
        isNodeInRubbishBin: Bool = false,
        isBackupsNode: Bool = false,
        isBackupsRootNode: Bool = false,
        maxCharactersAllowed: Int = 300,
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
