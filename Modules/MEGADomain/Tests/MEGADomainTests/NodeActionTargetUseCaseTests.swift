import XCTest
import MEGADomain
import MEGADomainMock

final class NodeActionTargetUseCaseTests: XCTestCase {
    let rootNode = NodeEntity(name: "root", handle: HandleEntity(1))
    let lastTargetNode = NodeEntity(name: "last_target", handle: HandleEntity(2))
    
    func testNodeActionTarget_lastMoveActionThirtyMinutesAgo() {
        let thirtyMinutesAgo = Calendar.current.date(byAdding: .minute, value: -30, to: Date())!
        let sut = NodeActionTargetUseCase(nodeRepo: MockNodeRepository(node: lastTargetNode, nodeRoot: rootNode), preferenceUseCase: MockPreferenceUseCase(dict: [.lastMoveActionTargetPath: HandleEntity(2), .lastMoveActionTargetDate: thirtyMinutesAgo]))
        XCTAssertEqual(sut.target(for: .move), lastTargetNode.handle)
    }
    
    func testNodeActionTarget_lastMoveActionTwoHoursAgo() {
        let twoHoursAgo = Calendar.current.date(byAdding: .minute, value: -120, to: Date())!
        let sut = NodeActionTargetUseCase(nodeRepo: MockNodeRepository(node: lastTargetNode, nodeRoot: rootNode), preferenceUseCase: MockPreferenceUseCase(dict: [.lastMoveActionTargetPath: HandleEntity(1), .lastMoveActionTargetDate: twoHoursAgo]))
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
        let sut = NodeActionTargetUseCase(nodeRepo: MockNodeRepository(node: lastTargetNode, nodeRoot: rootNode), preferenceUseCase: MockPreferenceUseCase(dict: [.lastCopyActionTargetPath: HandleEntity(2), .lastCopyActionTargetDate: thirtyMinutesAgo]))
        XCTAssertEqual(sut.target(for: .copy), lastTargetNode.handle)
    }
    
    func testNodeActionTarget_lastCopyActionTwoHoursAgo() {
        let twoHoursAgo = Calendar.current.date(byAdding: .minute, value: -120, to: Date())!
        let sut = NodeActionTargetUseCase(nodeRepo: MockNodeRepository(node: lastTargetNode, nodeRoot: rootNode), preferenceUseCase: MockPreferenceUseCase(dict: [.lastCopyActionTargetPath: HandleEntity(1), .lastCopyActionTargetDate: twoHoursAgo]))
        XCTAssertEqual(sut.target(for: .copy), rootNode.handle)
    }
    
    func testNodeActionTarget_updateLastCopyActionTarget() {
        let newTargetNode = NodeEntity(name: "new_target", handle: HandleEntity(3))
        let sut = NodeActionTargetUseCase(nodeRepo: MockNodeRepository(node: newTargetNode, nodeRoot: rootNode), preferenceUseCase: MockPreferenceUseCase(dict: [:]))
        sut.record(target: newTargetNode, for: .copy)
        XCTAssertEqual(sut.target(for: .copy), newTargetNode.handle)
    }
}
