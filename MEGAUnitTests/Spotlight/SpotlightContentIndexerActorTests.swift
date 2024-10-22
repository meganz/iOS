@testable import MEGA
import MEGADomain
import MEGADomainMock
import XCTest

final class SpotlightContentIndexerActorTests: XCTestCase {
    
    func testIndexSearchItems_shouldDeleteOldAndCreateNewItems() async {
        let nodes: [NodeEntity] = [
            NodeEntity(name: "1", handle: 1, base64Handle: "-1", isFile: true, size: 12),
            NodeEntity(name: "2", handle: 2, base64Handle: "-2", isFile: false, size: 0),
            NodeEntity(name: "3", handle: 3, base64Handle: "-3", isFile: true, size: 54)
        ]
        
        let spotlightSearchableIndexUseCase = MockSpotlightSearchableIndexUseCase()
                       
        let sut = makeSUT(
            favouritesUseCase: MockFavouriteNodesUseCase(
                getAllFavouriteNodesWithSearchResult: .success(nodes)),
            nodeAttributeUseCase: MockNodeAttributeUseCase(
                pathForNodes: nodes.reduce(into: [NodeEntity: String]()) { $0[$1] = $1.nodePath }),
            spotlightSearchableIndexUseCase: spotlightSearchableIndexUseCase)
        
        await sut.indexSearchableItems()
        
        let indexSearchableItemsCalledWith = spotlightSearchableIndexUseCase.indexSearchableItemsCalledWith
        
        XCTAssertTrue(spotlightSearchableIndexUseCase.deleteAllSearchableItemsCalled)
        
        XCTAssertEqual(indexSearchableItemsCalledWith.map(\.title), nodes.map(\.name))
        XCTAssertEqual(indexSearchableItemsCalledWith.map(\.contentDescription), nodes.map(\.contentDescription))
        XCTAssertEqual(indexSearchableItemsCalledWith.map(\.uniqueIdentifier), nodes.map(\.base64Handle))
    }
    
    func testDeleteAllSearchableItems_shouldDeleteAllItems() async {
        
        let spotlightSearchableIndexUseCase = MockSpotlightSearchableIndexUseCase()
                       
        let sut = makeSUT(
            spotlightSearchableIndexUseCase: spotlightSearchableIndexUseCase)
        
        await sut.deleteAllSearchableItems()
        
        XCTAssertTrue(spotlightSearchableIndexUseCase.deleteAllSearchableItemsCalled)
    }
    
    func testReIndexSearchItems_whenFavouriteChanged_shouldUpdateItems() async {
        let nodes: [NodeEntity] = [
            NodeEntity(name: "1", handle: 1, base64Handle: "-1", isFile: true, size: 12),
            NodeEntity(name: "2", handle: 2, base64Handle: "-2", isFile: false, size: 0),
            NodeEntity(name: "3", handle: 3, base64Handle: "-3", isFile: true, size: 54)
        ]
        
        let spotlightSearchableIndexUseCase = MockSpotlightSearchableIndexUseCase()
                       
        let sut = makeSUT(
            favouritesUseCase: MockFavouriteNodesUseCase(
                getAllFavouriteNodesWithSearchResult: .success(nodes)),
            nodeAttributeUseCase: MockNodeAttributeUseCase(
                pathForNodes: nodes.reduce(into: [NodeEntity: String]()) { $0[$1] = $1.nodePath }),
            spotlightSearchableIndexUseCase: spotlightSearchableIndexUseCase)
        
        for await favourite in [true, false].async {
            
            let updatedNodes: [NodeEntity] = [
                NodeEntity(changeTypes: .favourite, name: "1", handle: 1, base64Handle: "-1", isFile: true, isFavourite: favourite, size: 12)
            ]
            
            await sut.reindex(updatedNodes: updatedNodes)
            
            if favourite {
                
                let indexSearchableItemsCalledWith = spotlightSearchableIndexUseCase.indexSearchableItemsCalledWith
                let expectedNodes = updatedNodes
                
                XCTAssertEqual(indexSearchableItemsCalledWith.map(\.title), expectedNodes.map(\.name))
                XCTAssertEqual(indexSearchableItemsCalledWith.map(\.contentDescription), expectedNodes.map(\.contentDescription))
                XCTAssertEqual(indexSearchableItemsCalledWith.map(\.uniqueIdentifier), expectedNodes.map(\.base64Handle))
            } else {
                XCTAssertEqual(spotlightSearchableIndexUseCase.deleteSearchableItemsCalledWith, updatedNodes.map(\.base64Handle))
            }
        }
    }
    
    func testReIndexSearchItems_whenFileSensitivityChanged_shouldUpdateItems() async {
        let nodes: [NodeEntity] = [
            NodeEntity(name: "1", handle: 1, base64Handle: "-1", isFile: true, size: 12),
            NodeEntity(name: "2", handle: 2, base64Handle: "-2", isFile: false, size: 0),
            NodeEntity(name: "3", handle: 3, base64Handle: "-3", isFile: true, size: 54)
        ]
        
        let spotlightSearchableIndexUseCase = MockSpotlightSearchableIndexUseCase()
                       
        let sut = makeSUT(
            favouritesUseCase: MockFavouriteNodesUseCase(
                getAllFavouriteNodesWithSearchResult: .success(nodes)),
            nodeAttributeUseCase: MockNodeAttributeUseCase(
                pathForNodes: nodes.reduce(into: [NodeEntity: String]()) { $0[$1] = $1.nodePath }),
            spotlightSearchableIndexUseCase: spotlightSearchableIndexUseCase)
        
        for await isMarkedSensitive in [true, false].async {
            
            let updatedNodes: [NodeEntity] = [
                NodeEntity(changeTypes: .favourite, name: "1", handle: 1, base64Handle: "-1", isFile: true, isFavourite: true, isMarkedSensitive: isMarkedSensitive, size: 12)
            ]
            
            await sut.reindex(updatedNodes: updatedNodes)
            
            if isMarkedSensitive {
                XCTAssertEqual(spotlightSearchableIndexUseCase.deleteSearchableItemsCalledWith, updatedNodes.map(\.base64Handle))
            } else {
                let indexSearchableItemsCalledWith = spotlightSearchableIndexUseCase.indexSearchableItemsCalledWith
                let expectedNodes = updatedNodes
                
                XCTAssertEqual(indexSearchableItemsCalledWith.map(\.title), expectedNodes.map(\.name))
                XCTAssertEqual(indexSearchableItemsCalledWith.map(\.contentDescription), expectedNodes.map(\.contentDescription))
                XCTAssertEqual(indexSearchableItemsCalledWith.map(\.uniqueIdentifier), expectedNodes.map(\.base64Handle))
            }
        }
    }
    
    func testReIndexSearchItems_whenFolderIsMarkedSensitive_shouldReindexCompletely() async {
        let nodes: [NodeEntity] = [
            NodeEntity(name: "1", handle: 1, base64Handle: "-1", isFile: true, size: 12),
            NodeEntity(name: "2", handle: 2, base64Handle: "-2", isFile: false, size: 0),
            NodeEntity(name: "3", handle: 3, base64Handle: "-3", isFile: true, size: 54)
        ]
        
        let spotlightSearchableIndexUseCase = MockSpotlightSearchableIndexUseCase()
        
        let sut = makeSUT(
            favouritesUseCase: MockFavouriteNodesUseCase(
                getAllFavouriteNodesWithSearchResult: .success(nodes)),
            nodeAttributeUseCase: MockNodeAttributeUseCase(
                pathForNodes: nodes.reduce(into: [NodeEntity: String]()) { $0[$1] = $1.nodePath }),
            spotlightSearchableIndexUseCase: spotlightSearchableIndexUseCase)
        
        let updatedNodes: [NodeEntity] = [
            NodeEntity(changeTypes: .sensitive, name: "1", handle: 1, base64Handle: "-1", isFolder: true, isFavourite: true, size: 12)
        ]
        
        await sut.reindex(updatedNodes: updatedNodes)
        
        let indexSearchableItemsCalledWith = spotlightSearchableIndexUseCase.indexSearchableItemsCalledWith
        
        XCTAssertTrue(spotlightSearchableIndexUseCase.deleteAllSearchableItemsCalled)
        
        XCTAssertEqual(indexSearchableItemsCalledWith.map(\.title), nodes.map(\.name))
        XCTAssertEqual(indexSearchableItemsCalledWith.map(\.contentDescription), nodes.map(\.contentDescription))
        XCTAssertEqual(indexSearchableItemsCalledWith.map(\.uniqueIdentifier), nodes.map(\.base64Handle))
    }
}

extension SpotlightContentIndexerActorTests {
    func makeSUT(
        favouritesUseCase: some FavouriteNodesUseCaseProtocol = MockFavouriteNodesUseCase(),
        nodeAttributeUseCase: some NodeAttributeUseCaseProtocol = MockNodeAttributeUseCase(),
        spotlightSearchableIndexUseCase: some SpotlightSearchableIndexUseCaseProtocol = MockSpotlightSearchableIndexUseCase(),
        featureFlagHiddenNodes: Bool = true
    ) -> SpotlightContentIndexerActor {
        let sut = SpotlightContentIndexerActor(
            favouritesUseCase: favouritesUseCase,
            nodeAttributeUseCase: nodeAttributeUseCase,
            spotlightSearchableIndexUseCase: spotlightSearchableIndexUseCase,
            remoteFeatureFlagUseCase: MockRemoteFeatureFlagUseCase(list: [.hiddenNodes: featureFlagHiddenNodes]))
        trackForMemoryLeaks(on: sut)
        return sut
    }
}

fileprivate extension NodeEntity {
    var contentDescription: String {
        if isFile {
            ByteCountFormatter.string(fromByteCount: Int64(size), countStyle: .file)
        } else {
            nodePath
        }
    }
    
    var nodePath: String {
        "path/test/folder/\(name)"
    }
}
