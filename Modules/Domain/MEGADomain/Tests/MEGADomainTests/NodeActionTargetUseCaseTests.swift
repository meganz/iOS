import MEGADomain
import MEGADomainMock
import MEGAPreference
import XCTest

final class NodeActionTargetUseCaseTests: XCTestCase {
    let rootNode = NodeEntity(name: "root", handle: HandleEntity(1))
    let lastTargetNode = NodeEntity(name: "last_target", handle: HandleEntity(2))
    
    func testNodeActionTarget_lastMoveActionThirtyMinutesAgo() {
        let thirtyMinutesAgo = Calendar.current.date(byAdding: .minute, value: -30, to: Date())!
        let sut = NodeActionTargetUseCase(nodeRepo: MockNodeRepository(node: lastTargetNode, nodeRoot: rootNode), preferenceUseCase: MockPreferenceUseCase(dict: [PreferenceKeyEntity.lastMoveActionTargetPath.rawValue: HandleEntity(2), PreferenceKeyEntity.lastMoveActionTargetDate.rawValue: thirtyMinutesAgo]))
        XCTAssertEqual(sut.target(for: .move), lastTargetNode.handle)
    }
    
    func testNodeActionTarget_lastMoveActionTwoHoursAgo() {
        let twoHoursAgo = Calendar.current.date(byAdding: .minute, value: -120, to: Date())!
        let sut = NodeActionTargetUseCase(nodeRepo: MockNodeRepository(node: lastTargetNode, nodeRoot: rootNode), preferenceUseCase: MockPreferenceUseCase(dict: [PreferenceKeyEntity.lastMoveActionTargetPath.rawValue: HandleEntity(1), PreferenceKeyEntity.lastMoveActionTargetDate.rawValue: twoHoursAgo]))
        XCTAssertEqual(sut.target(for: .move), rootNode.handle)
    }
    
    func testNodeActionTarget_updateLastMoveActionTarget() {
        let newTargetNode = NodeEntity(name: "new_target", handle: HandleEntity(3))
        let sut = NodeActionTargetUseCase(nodeRepo: MockNodeRepository(node: newTargetNode, nodeRoot: rootNode), preferenceUseCase: MockPreferenceUseCase(dict: [:]))
        sut.record(target: newTargetNode, for: .move)
        XCTAssertEqual(sut.target(for: .move), newTargetNode.handle)
    }
    
    func testNodeActionTarget_lastCopyActionThirtyMinutesAgo() {
        let thirtyMinutesAgo = Calendar.current.date(byAdding: .minute, value: -30, to: Date())!
        let sut = NodeActionTargetUseCase(nodeRepo: MockNodeRepository(node: lastTargetNode, nodeRoot: rootNode), preferenceUseCase: MockPreferenceUseCase(dict: [PreferenceKeyEntity.lastCopyActionTargetPath.rawValue: HandleEntity(2), PreferenceKeyEntity.lastCopyActionTargetDate.rawValue: thirtyMinutesAgo]))
        XCTAssertEqual(sut.target(for: .copy), lastTargetNode.handle)
    }
    
    func testNodeActionTarget_lastCopyActionTwoHoursAgo() {
        let twoHoursAgo = Calendar.current.date(byAdding: .minute, value: -120, to: Date())!
        let sut = NodeActionTargetUseCase(nodeRepo: MockNodeRepository(node: lastTargetNode, nodeRoot: rootNode), preferenceUseCase: MockPreferenceUseCase(dict: [PreferenceKeyEntity.lastCopyActionTargetPath.rawValue: HandleEntity(1), PreferenceKeyEntity.lastCopyActionTargetDate.rawValue: twoHoursAgo]))
        XCTAssertEqual(sut.target(for: .copy), rootNode.handle)
    }
    
    func testNodeActionTarget_updateLastCopyActionTarget() {
        let newTargetNode = NodeEntity(name: "new_target", handle: HandleEntity(3))
        let sut = NodeActionTargetUseCase(nodeRepo: MockNodeRepository(node: newTargetNode, nodeRoot: rootNode), preferenceUseCase: MockPreferenceUseCase(dict: [:]))
        sut.record(target: newTargetNode, for: .copy)
        XCTAssertEqual(sut.target(for: .copy), newTargetNode.handle)
    }
}
