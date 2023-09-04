@testable import MEGA
import MEGADomain
import MEGASDKRepoMock
import MEGATest
import XCTest

final class AudioPlayerViewRouterNodeActionAdapterTests: XCTestCase {
    
    func testNodeAction_fromFileLinkNode_fordwardsCorrectDelegate() {
        let link = "any-file-link"
        let sut = makeSUT(configEntity: audioPlayerConfigEntity(from: .fileLink, fileLink: link, relatedFiles: nil))
        
        sut.nodeAction(mockNodeActionViewController(), didSelect: .rename, for: MockNode(handle: 1), from: "any-sender")
        
        guard let mockNodeActionDelegate = sut.nodeActionViewControllerDelegate as? MockNodeActionViewControllerGenericDelegate else {
            XCTFail("Expect to have mock type of : \(type(of: MockNodeActionViewControllerGenericDelegate.self))")
            return
        }
        XCTAssertEqual(mockNodeActionDelegate.didSelectNodeActionCallCount, 0)
    }
    
    func testNodeAction_fromNonFileLinkNode_fordwardsCorrectDelegate() {
        AudioPlayerConfigEntity.NodeOriginType.allCases
            .filter { $0 == .fileLink }
            .map { audioPlayerConfigEntity(from: $0) }
            .enumerated()
            .forEach { (index, configEntity) in
                
                let sut = makeSUT(configEntity: configEntity)
                
                sut.nodeAction(mockNodeActionViewController(), didSelect: .rename, for: MockNode(handle: 1), from: "any-sender")
                
                guard let mockNodeActionDelegate = sut.nodeActionViewControllerDelegate as? MockNodeActionViewControllerGenericDelegate else {
                    XCTFail("Expect to have mock type of : \(type(of: MockNodeActionViewControllerGenericDelegate.self))")
                    return
                }
                XCTAssertEqual(mockNodeActionDelegate.didSelectNodeActionCallCount, 1, "Fail at index: \(index)")
            }
    }
    
    // MARK: - Helpers
    
    private func makeSUT(configEntity: AudioPlayerConfigEntity, file: StaticString = #filePath, line: UInt = #line) -> AudioPlayerViewRouterNodeActionAdapter {
        let sut = AudioPlayerViewRouterNodeActionAdapter(
            configEntity: configEntity,
            nodeActionViewControllerDelegate: MockNodeActionViewControllerGenericDelegate(viewController: UIViewController()),
            fileLinkActionViewControllerDelegate: FileLinkActionViewControllerDelegate(link: "any-link", viewController: UIViewController())
        )
        trackForMemoryLeaks(on: sut, file: file, line: line)
        return sut
    }
    
    private func mockNodeActionViewController() -> NodeActionViewController {
        NodeActionViewController(
            node: MockNode(handle: 1),
            delegate: MockNodeActionViewControllerGenericDelegate(viewController: UIViewController()),
            displayMode: .albumLink,
            isInVersionsView: false,
            isBackupNode: false,
            sender: "any-sender"
        )
    }
    
    private func audioPlayerConfigEntity(
        from originType: AudioPlayerConfigEntity.NodeOriginType,
        fileLink: String? = nil,
        messageId: HandleEntity? = nil,
        chatId: HandleEntity? = nil,
        relatedFiles: [String]? = nil,
        playerHandler: MockAudioPlayerHandler = MockAudioPlayerHandler()
    ) -> AudioPlayerConfigEntity {
        let node = MockNode(handle: .max)
        
        switch originType {
        case .folderLink:
            return AudioPlayerConfigEntity(node: node, isFolderLink: true, fileLink: nil, messageId: .invalid, chatId: .invalid, relatedFiles: relatedFiles, playerHandler: playerHandler)
        case .fileLink:
            return AudioPlayerConfigEntity(node: node, isFolderLink: false, fileLink: fileLink, messageId: .invalid, chatId: .invalid, relatedFiles: relatedFiles, playerHandler: playerHandler)
        case .chat:
            return AudioPlayerConfigEntity(node: node, isFolderLink: false, fileLink: nil, messageId: messageId, chatId: chatId, relatedFiles: relatedFiles, playerHandler: playerHandler)
        case .unknown:
            return AudioPlayerConfigEntity(node: node, isFolderLink: false, fileLink: nil, messageId: .invalid, chatId: .invalid, relatedFiles: relatedFiles, playerHandler: playerHandler)
        }
    }
    
}

private final class MockNodeActionViewControllerGenericDelegate: NodeActionViewControllerGenericDelegate {
    
    private(set) var didSelectNodeActionCallCount = 0
    
    override func nodeAction(_ nodeAction: NodeActionViewController, didSelect action: MegaNodeActionType, for node: MEGANode, from sender: Any) {
        didSelectNodeActionCallCount += 1
    }
}
