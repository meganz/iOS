@testable import MEGA
import MEGAAppSDKRepo
import MEGAAppSDKRepoMock
import MEGADomain
import MEGADomainMock
import MEGASwift
import Testing

@Suite("Spotlight contect indexer actor tests")
struct SpotlightContentIndexerActorTests {
    private let nodes: [NodeEntity] = [
        NodeEntity(name: "1", handle: 1, base64Handle: "-1", isFile: true, size: 12),
        NodeEntity(name: "2", handle: 2, base64Handle: "-2", isFile: false, size: 0),
        NodeEntity(name: "3", handle: 3, base64Handle: "-3", isFile: true, size: 54)
    ]
    
    @Test("Index search items should delete old item and create new items")
    func testIndexSearchItems_shouldDeleteOldAndCreateNewItems() async {
        let spotlightSearchableIndexUseCase = MockSpotlightSearchableIndexUseCase()
                       
        let sut = makeSUT(
            favouritesUseCase: MockFavouriteNodesUseCase(
                getAllFavouriteNodesWithSearchResult: .success(nodes)),
            nodeAttributeUseCase: MockNodeAttributeUseCase(
                pathForNodes: nodes.reduce(into: [NodeEntity: String]()) { $0[$1] = $1.nodePath }),
            spotlightSearchableIndexUseCase: spotlightSearchableIndexUseCase)
        
        await sut.indexSearchableItems()
        
        let indexSearchableItemsCalledWith = spotlightSearchableIndexUseCase.indexSearchableItemsCalledWith
        
        #expect(spotlightSearchableIndexUseCase.deleteAllSearchableItemsCalled)
        
        #expect(indexSearchableItemsCalledWith.map(\.title) == nodes.map(\.name))
        #expect(indexSearchableItemsCalledWith.map(\.contentDescription) == nodes.map(\.contentDescription))
        #expect(indexSearchableItemsCalledWith.map(\.uniqueIdentifier) == nodes.map(\.base64Handle))
    }
    
    @Test("Delete all searchable items")
    func testDeleteAllSearchableItems_shouldDeleteAllItems() async {
        let spotlightSearchableIndexUseCase = MockSpotlightSearchableIndexUseCase()
                       
        let sut = makeSUT(
            spotlightSearchableIndexUseCase: spotlightSearchableIndexUseCase)
        
        await sut.deleteAllSearchableItems()
        
        #expect(spotlightSearchableIndexUseCase.deleteAllSearchableItemsCalled)
    }
    
    @Test("Reindex search items when favourite changed", arguments: [true, false])
    func testReIndexSearchItems_whenFavouriteChanged_shouldUpdateItems(favourite: Bool) async {
        let spotlightSearchableIndexUseCase = MockSpotlightSearchableIndexUseCase()
                       
        let sut = makeSUT(
            favouritesUseCase: MockFavouriteNodesUseCase(
                getAllFavouriteNodesWithSearchResult: .success(nodes)),
            nodeAttributeUseCase: MockNodeAttributeUseCase(
                pathForNodes: nodes.reduce(into: [NodeEntity: String]()) { $0[$1] = $1.nodePath }),
            spotlightSearchableIndexUseCase: spotlightSearchableIndexUseCase)
        
        let updatedNodes: [NodeEntity] = [
            NodeEntity(changeTypes: .favourite, name: "1", handle: 1, base64Handle: "-1", isFile: true, isFavourite: favourite, size: 12)
        ]
        
        await sut.reindex(updatedNodes: updatedNodes)
        
        if favourite {
            let indexSearchableItemsCalledWith = spotlightSearchableIndexUseCase.indexSearchableItemsCalledWith
            #expect(indexSearchableItemsCalledWith.map(\.title) == updatedNodes.map(\.name))
            #expect(indexSearchableItemsCalledWith.map(\.contentDescription) == updatedNodes.map(\.contentDescription))
            #expect(indexSearchableItemsCalledWith.map(\.uniqueIdentifier) == updatedNodes.map(\.base64Handle))
        } else {
            #expect(spotlightSearchableIndexUseCase.deleteSearchableItemsCalledWith == updatedNodes.map(\.base64Handle))
        }
    }
    
    @Test("Monitor nodes updates", arguments: [true, false])
    func monitorNodesUpdate(favourite: Bool) async {
        let spotlightSearchableIndexUseCase = MockSpotlightSearchableIndexUseCase()
        let updatedNodes: [NodeEntity] = [
            NodeEntity(changeTypes: .favourite, name: "1", handle: 1, base64Handle: "-1", isFile: true, isFavourite: favourite, size: 12)
        ]
        let updateSequence = SingleItemAsyncSequence(item: updatedNodes)
            .eraseToAnyAsyncSequence()
        let nodeUpdatesProvider = MockNodeUpdatesProvider(nodeUpdates: updateSequence)
                       
        let sut = makeSUT(
            favouritesUseCase: MockFavouriteNodesUseCase(
                getAllFavouriteNodesWithSearchResult: .success(nodes)),
            nodeAttributeUseCase: MockNodeAttributeUseCase(
                pathForNodes: nodes.reduce(into: [NodeEntity: String]()) { $0[$1] = $1.nodePath }),
            spotlightSearchableIndexUseCase: spotlightSearchableIndexUseCase,
            nodeUpdatesProvider: nodeUpdatesProvider)
        
        await sut.monitorNodesUpdates()
        
        if favourite {
            let indexSearchableItemsCalledWith = spotlightSearchableIndexUseCase.indexSearchableItemsCalledWith
            #expect(indexSearchableItemsCalledWith.map(\.title) == updatedNodes.map(\.name))
            #expect(indexSearchableItemsCalledWith.map(\.contentDescription) == updatedNodes.map(\.contentDescription))
            #expect(indexSearchableItemsCalledWith.map(\.uniqueIdentifier) == updatedNodes.map(\.base64Handle))
        } else {
            #expect(spotlightSearchableIndexUseCase.deleteSearchableItemsCalledWith == updatedNodes.map(\.base64Handle))
        }
    }
    
    @Test("Reindex search items when file sensitivity changed", arguments: [true, false])
    func testReIndexSearchItems_whenFileSensitivityChanged_shouldUpdateItems(isMarkedSensitive: Bool) async {
        let spotlightSearchableIndexUseCase = MockSpotlightSearchableIndexUseCase()
                       
        let sut = makeSUT(
            favouritesUseCase: MockFavouriteNodesUseCase(
                getAllFavouriteNodesWithSearchResult: .success(nodes)),
            nodeAttributeUseCase: MockNodeAttributeUseCase(
                pathForNodes: nodes.reduce(into: [NodeEntity: String]()) { $0[$1] = $1.nodePath }),
            spotlightSearchableIndexUseCase: spotlightSearchableIndexUseCase)
        
        let updatedNodes: [NodeEntity] = [
            NodeEntity(changeTypes: .favourite, name: "1", handle: 1, base64Handle: "-1", isFile: true, isFavourite: true, isMarkedSensitive: isMarkedSensitive, size: 12)
        ]
        
        await sut.reindex(updatedNodes: updatedNodes)
        
        if isMarkedSensitive {
            #expect(spotlightSearchableIndexUseCase.deleteSearchableItemsCalledWith == updatedNodes.map(\.base64Handle))
        } else {
            let indexSearchableItemsCalledWith = spotlightSearchableIndexUseCase.indexSearchableItemsCalledWith
            #expect(indexSearchableItemsCalledWith.map(\.title) == updatedNodes.map(\.name))
            #expect(indexSearchableItemsCalledWith.map(\.contentDescription) == updatedNodes.map(\.contentDescription))
            #expect(indexSearchableItemsCalledWith.map(\.uniqueIdentifier) == updatedNodes.map(\.base64Handle))
        }
    }
    
    @Test("Reindex search items when folder is marked sensitive")
    func testReIndexSearchItems_whenFolderIsMarkedSensitive_shouldReindexCompletely() async {
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
        
        #expect(spotlightSearchableIndexUseCase.deleteAllSearchableItemsCalled)
        
        #expect(indexSearchableItemsCalledWith.map(\.title) == nodes.map(\.name))
        #expect(indexSearchableItemsCalledWith.map(\.contentDescription) == nodes.map(\.contentDescription))
        #expect(indexSearchableItemsCalledWith.map(\.uniqueIdentifier) == nodes.map(\.base64Handle))
    }
}

extension SpotlightContentIndexerActorTests {
    func makeSUT(
        favouritesUseCase: some FavouriteNodesUseCaseProtocol = MockFavouriteNodesUseCase(),
        nodeAttributeUseCase: some NodeAttributeUseCaseProtocol = MockNodeAttributeUseCase(),
        spotlightSearchableIndexUseCase: some SpotlightSearchableIndexUseCaseProtocol = MockSpotlightSearchableIndexUseCase(),
        featureFlagHiddenNodes: Bool = true,
        nodeUpdatesProvider: some NodeUpdatesProviderProtocol = MockNodeUpdatesProvider()
    ) -> SpotlightContentIndexerActor {
        let sut = SpotlightContentIndexerActor(
            favouritesUseCase: favouritesUseCase,
            nodeAttributeUseCase: nodeAttributeUseCase,
            spotlightSearchableIndexUseCase: spotlightSearchableIndexUseCase,
            remoteFeatureFlagUseCase: MockRemoteFeatureFlagUseCase(list: [.hiddenNodes: featureFlagHiddenNodes]),
            nodeUpdatesProvider: nodeUpdatesProvider)
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
