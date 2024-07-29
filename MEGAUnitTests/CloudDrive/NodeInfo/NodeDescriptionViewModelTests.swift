@testable import MEGA
import MEGADomain
import MEGADomainMock
import XCTest

final class NodeDescriptionViewModelTests: XCTestCase {

    func testHasReadOnlyAccess_forNodeOwnerAndFullAccessLevel_shouldHaveWriteAccess() {
        let nodeAccess: [NodeAccessTypeEntity] = [.owner, .full]
        nodeAccess.forEach {
            let sut = makeSUT(accessType: $0)
            XCTAssertFalse(sut.hasReadOnlyAccess, "Expected write access for \($0)")
        }
    }

    func testHasReadOnlyAccess_forAccessLevelBelowFullAccess_shouldHaveReadOnlyAccess() {
        let nodeAccess: [NodeAccessTypeEntity] = [.readWrite, .read, .unknown]
        nodeAccess.forEach {
            let sut = makeSUT(accessType: $0)
            XCTAssertTrue(sut.hasReadOnlyAccess, "Expected read access for \($0)")
        }
    }

    func testHasReadOnlyAccess_forNodeInRubbishBin_shouldHaveReadOnlyAccess() {
        let sut = makeSUT(isNodeInRubbishBin: true)
        XCTAssertTrue(sut.hasReadOnlyAccess)
    }

    func testHasReadOnlyAccess_forNodeInBackup_shouldHaveReadOnlyAccess() {
        let sut = makeSUT(isBackupsNode: true)
        XCTAssertTrue(sut.hasReadOnlyAccess)
    }

    func testHasReadOnlyAccess_forBackupNodeRootNode_shouldHaveReadOnlyAccess() {
        let sut = makeSUT(isBackupsRootNode: true)
        XCTAssertTrue(sut.hasReadOnlyAccess)
    }

    // MARK: - Helpers

    private func makeSUT(
        accessType: NodeAccessTypeEntity = .owner,
        isNodeInRubbishBin: Bool = false,
        isBackupsNode: Bool = false,
        isBackupsRootNode: Bool = false,
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
        return makeSUT(
            nodeUseCase: nodeUseCase,
            backupUseCase: backupUseCase,
            file: file,
            line: line
        )
    }

    private func makeSUT(
        node: NodeEntity = NodeEntity(),
        nodeUseCase: some NodeUseCaseProtocol = MockNodeDataUseCase(),
        backupUseCase: some BackupsUseCaseProtocol = MockBackupsUseCase(),
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> NodeDescriptionViewModel {
        let sut = NodeDescriptionViewModel(
            node: node,
            nodeUseCase: nodeUseCase,
            backupUseCase: backupUseCase
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
