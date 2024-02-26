@testable import MEGA
import MEGADomain
import MEGAPresentation
import MEGAPresentationMock
import XCTest

final class NodeActionViewModelTests: XCTestCase {

    func testIsNodeHidden_hiddenNodeFeatureOff_shouldReturnFalse() {
        let node = NodeEntity(handle: 65, isMarkedSensitive: true)
        let featureFlagProvider = MockFeatureFlagProvider(list: [.hiddenNodes: false])
        let sut = makeSUT(featureFlagProvider: featureFlagProvider)
        
        XCTAssertNil(sut.isNodeHidden(node))
    }
    
    func testIsNodeHidden_nodeMarkedAsSensitive_resultShouldMatchSensitiveState() throws {
        try [true, false].forEach {
            let node = NodeEntity(handle: 65, isMarkedSensitive: $0)
            let featureFlagProvider = MockFeatureFlagProvider(list: [.hiddenNodes: true])
            let sut = makeSUT(featureFlagProvider: featureFlagProvider)
            
            let isHidden = try XCTUnwrap(sut.isNodeHidden(node))
            XCTAssertEqual(isHidden, $0)
        }
    }

    private func makeSUT(
        featureFlagProvider: some FeatureFlagProviderProtocol = MockFeatureFlagProvider(list: [:])
    ) -> NodeActionViewModel {
        NodeActionViewModel(featureFlagProvider: featureFlagProvider)
    }
}
