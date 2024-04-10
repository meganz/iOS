@testable import MEGA
import MEGADomain
import MEGADomainMock
import MEGAPresentation
import MEGAPresentationMock
import XCTest

final class NodeActionViewModelTests: XCTestCase {

    func testContainsOnlySensitiveNodes_hiddenNodeFeatureOff_shouldReturnNil() {
        let node = NodeEntity(handle: 65, isMarkedSensitive: true)
        let featureFlagProvider = MockFeatureFlagProvider(list: [.hiddenNodes: false])
        let sut = makeSUT(featureFlagProvider: featureFlagProvider)
        
        XCTAssertNil(sut.containsOnlySensitiveNodes([node], isFromSharedItem: false))
    }
    
    func testContainsOnlySensitiveNodes_nodesContainsOnlySensitiveNodes_shouldReturnTrue() throws {
        let nodes = makeSensitiveNodes()
        let featureFlagProvider = MockFeatureFlagProvider(list: [.hiddenNodes: true])
        let sut = makeSUT(featureFlagProvider: featureFlagProvider)
        
        let containsOnlySensitiveNodes = try XCTUnwrap(sut.containsOnlySensitiveNodes(nodes, isFromSharedItem: false))
        
        XCTAssertTrue(containsOnlySensitiveNodes)
    }
    
    func testContainsOnlySensitiveNodes_nodesContainsOnlySensitiveNodes_shouldReturnFalse() throws {
        var nodes = makeSensitiveNodes()
        nodes.append(NodeEntity(handle: HandleEntity(nodes.count + 1), isMarkedSensitive: false))
        let featureFlagProvider = MockFeatureFlagProvider(list: [.hiddenNodes: true])
        let sut = makeSUT(featureFlagProvider: featureFlagProvider)
        
        let containsOnlySensitiveNodes = try XCTUnwrap(sut.containsOnlySensitiveNodes(nodes, isFromSharedItem: false))
        
        XCTAssertFalse(containsOnlySensitiveNodes)
    }
    
    func testContainsOnlySensitiveNodes_isFromSharedItemIsTrue_shouldReturnNil() throws {
        [true, false].forEach {
            let node = NodeEntity(handle: 65, isMarkedSensitive: $0)
            let featureFlagProvider = MockFeatureFlagProvider(list: [.hiddenNodes: true])
            let sut = makeSUT(featureFlagProvider: featureFlagProvider)
            
            XCTAssertNil(sut.containsOnlySensitiveNodes([node], isFromSharedItem: true))
        }
    }

    func testAccountType_shouldReturnCurrentAccountProLevel() {
        let expectedAccountType = AccountTypeEntity.proI
        let accountUseCase = MockAccountUseCase(
            currentAccountDetails: AccountDetailsEntity(proLevel: expectedAccountType))
        
        let sut = makeSUT(accountUseCase: accountUseCase)
        
        XCTAssertEqual(sut.accountType, expectedAccountType)
    }
    
    private func makeSUT(
        accountUseCase: some AccountUseCaseProtocol = MockAccountUseCase(),
        featureFlagProvider: some FeatureFlagProviderProtocol = MockFeatureFlagProvider(list: [:])
    ) -> NodeActionViewModel {
        NodeActionViewModel(accountUseCase: accountUseCase,
                            featureFlagProvider: featureFlagProvider)
    }
    
    private func makeSensitiveNodes() -> [NodeEntity] {
        (0..<5).map {
            NodeEntity(handle: $0, isMarkedSensitive: true)
        }
    }
}
