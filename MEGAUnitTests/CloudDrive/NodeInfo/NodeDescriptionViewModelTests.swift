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

    func testUpdateDescriptionString_whenDescriptionAddedSuccessfully_shouldReturnStateAsAdded() async {
        let sut = makeSUT(description: nil) { result in
            XCTAssertEqual(result, .added)
        }

        await sut.save(descriptionString: "Hello World!")
    }

    func testUpdateDescriptionString_whenDescriptionUpdatedSuccessfully_shouldReturnStateAsUpdated() async {
        let sut = makeSUT {
            XCTAssertEqual($0, .updated)
        }
        await sut.save(descriptionString: "Hello World!")
    }

    func testUpdateDescriptionString_whenDescriptionRemovedSuccessfully_shouldReturnStateAsRemoved() async {
        let sut = makeSUT {
            XCTAssertEqual($0, .removed)
        }
        await sut.save(descriptionString: "")
    }

    func testUpdateDescriptionString_whenUseCaseReturnsFailure_shouldReturnNil() async {
        let sut = makeSUT(nodeDescriptionResult: .failure(NSError(domain: "", code: 0))) {
            XCTAssertNil($0)
        }
        await sut.save(descriptionString: "")
    }

    // MARK: - Helpers

    private func makeSUT(
        description: String? = "any description",
        accessType: NodeAccessTypeEntity = .owner,
        isNodeInRubbishBin: Bool = false,
        isBackupsNode: Bool = false,
        isBackupsRootNode: Bool = false,
        nodeDescriptionResult: Result<NodeEntity, any Error> = .success(NodeEntity()),
        descriptionSaved: @escaping (NodeDescriptionViewModel.SavedState) -> Void = { _ in },
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> NodeDescriptionViewModel {
        let nodeUseCase = MockNodeDataUseCase(
            nodeAccessLevelVariable: accessType,
            isNodeInRubbishBin: { _ in isNodeInRubbishBin }
        )
        let backupUseCase = MockBackupsUseCase(
            isBackupsNode: isBackupsNode,
            isBackupsRootNode: isBackupsRootNode
        )
        let sut = NodeDescriptionViewModel(
            node: NodeEntity(description: description),
            nodeUseCase: nodeUseCase,
            backupUseCase: backupUseCase,
            nodeDescriptionUseCase: MockNodeDescriptionUseCase(result: nodeDescriptionResult), 
            descriptionSaved: descriptionSaved
        )
        trackForMemoryLeaks(on: sut)
        return sut
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
