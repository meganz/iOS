@testable import MEGA
import MEGADomain
import MEGAPresentation
import MEGAPresentationMock
import XCTest

final class NodeActionViewModelTests: XCTestCase {

    func testContainsOnlySensitiveNodes_hiddenNodeFeatureOff_shouldReturnNil() {
        let node = NodeEntity(handle: 65, isMarkedSensitive: true)
        let featureFlagProvider = MockFeatureFlagProvider(list: [.hiddenNodes: false])
        let sut = makeSUT(featureFlagProvider: featureFlagProvider)
        
        XCTAssertNil(sut.containsOnlySensitiveNodes([node]))
    }
    
    func testContainsOnlySensitiveNodes_nodesContainsOnlySensitiveNodes_shouldReturnTrue() throws {
        let nodes = makeSensitiveNodes()
        let featureFlagProvider = MockFeatureFlagProvider(list: [.hiddenNodes: true])
        let sut = makeSUT(featureFlagProvider: featureFlagProvider)
        
        let containsOnlySensitiveNodes = try XCTUnwrap(sut.containsOnlySensitiveNodes(nodes))
        
        XCTAssertTrue(containsOnlySensitiveNodes)
    }
    
    func testContainsOnlySensitiveNodes_nodesContainsOnlySensitiveNodes_shouldReturnFalse() throws {
        var nodes = makeSensitiveNodes()
        nodes.append(NodeEntity(handle: HandleEntity(nodes.count + 1), isMarkedSensitive: false))
        let featureFlagProvider = MockFeatureFlagProvider(list: [.hiddenNodes: true])
        let sut = makeSUT(featureFlagProvider: featureFlagProvider)
        
        let containsOnlySensitiveNodes = try XCTUnwrap(sut.containsOnlySensitiveNodes(nodes))
        
        XCTAssertFalse(containsOnlySensitiveNodes)
    }

    private func makeSUT(
        featureFlagProvider: some FeatureFlagProviderProtocol = MockFeatureFlagProvider(list: [:])
    ) -> NodeActionViewModel {
        NodeActionViewModel(featureFlagProvider: featureFlagProvider)
    }
    
    private func makeSensitiveNodes() -> [NodeEntity] {
        (0..<5).map {
            NodeEntity(handle: $0, isMarkedSensitive: true)
        }
    }
}
