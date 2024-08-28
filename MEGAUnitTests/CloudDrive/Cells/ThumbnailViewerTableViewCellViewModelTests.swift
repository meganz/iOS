@testable import MEGA
import MEGADomain
import MEGADomainMock
import MEGAPresentation
import MEGAPresentationMock
import MEGASdk
import MEGASDKRepoMock
import XCTest

final class ThumbnailViewerTableViewCellViewModelTests: XCTestCase {
    
    @MainActor
    func testItemForIndex_indexWithinRange_shouldReturnViewModel() {
        let nodes = [
            NodeEntity(handle: 1),
            NodeEntity(handle: 2),
            NodeEntity(handle: 3)
        ]
        
        let sut = self.sut(nodes: nodes)
        
        (0..<nodes.count).forEach { index in
            let result = sut.item(for: index)
            XCTAssertNotNil(result)
        }
    }
    
    @MainActor
    func testItemForIndex_indexOutsideRange_shouldReturnNil() {
        let nodes = [
            NodeEntity(handle: 1),
            NodeEntity(handle: 2),
            NodeEntity(handle: 3)
        ]
        
        let sut = self.sut(nodes: nodes)
        
        [-1, 3, 4].forEach { index in
            let result = sut.item(for: index)
            XCTAssertNil(result)
        }
    }
}

extension ThumbnailViewerTableViewCellViewModelTests {
    
    @MainActor
    func sut(nodes: [NodeEntity] = [],
             nodeUseCase: some NodeUseCaseProtocol = MockNodeDataUseCase(),
             featureFlagHiddenNodes: Bool = false) -> ThumbnailViewerTableViewCellViewModel {
        ThumbnailViewerTableViewCellViewModel(
            nodes: nodes,
            nodeUseCase: nodeUseCase, 
            nodeIconUseCase: MockNodeIconUsecase(stubbedIconData: Data()), 
            thumbnailUseCase: MockThumbnailUseCase(),
            featureFlagProvider: MockFeatureFlagProvider(list: [.hiddenNodes: featureFlagHiddenNodes]))
    }
}
