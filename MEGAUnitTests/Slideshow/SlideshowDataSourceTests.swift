@preconcurrency import Combine
@testable import MEGA
import MEGADomain
import MEGADomainMock
import MEGATest
import Testing

struct SlideShowDataSourceTests {
    
    @MainActor
    @Suite("calls indexOfCurrentPhoto", .serialized)
    struct IndexOfCurrentPhoto {
        @Test("when sorted by oldest, should return correct index", arguments: [
            (NodeEntity(handle: 4), 3),
            (NodeEntity(handle: 10), 9),
            (NodeEntity(handle: 18), 17),
            (NodeEntity(handle: 38), 37)
        ])
        func indexOfCurrentPhotoWhenSortedByOldest(nodeEntity: NodeEntity, expectedIndex: Int) async throws {
            let thumbnailUrl = try Test.makeImageURL()
            let sut = sut(
                initialPhoto: nodeEntity,
                thumbnailUrl: thumbnailUrl)
            
            sut.sortNodes(byOrder: .oldest)
            
            #expect(sut.indexOfCurrentPhoto() == expectedIndex)
            
            try Test.removeImage(localURL: thumbnailUrl)
        }
        
        @Test("when sorted by newest, should return correct index", arguments: [
            (NodeEntity(handle: 4), 36),
            (NodeEntity(handle: 10), 30),
            (NodeEntity(handle: 18), 22),
            (NodeEntity(handle: 38), 2)
        ])
        func indexOfCurrentPhotoWhenSortedByNewest(nodeEntity: NodeEntity, expectedIndex: Int) async throws {
            let thumbnailUrl = try Test.makeImageURL()
            let sut = sut(
                initialPhoto: nodeEntity,
                thumbnailUrl: thumbnailUrl)
            
            sut.sortNodes(byOrder: .newest)
            
            #expect(sut.indexOfCurrentPhoto() == expectedIndex)

            try Test.removeImage(localURL: thumbnailUrl)
        }
    }
    
    @MainActor
    @Suite("calls loadSelectedPhotoPreview", .timeLimit(.minutes(1)))
    struct LoadSelectedPhotoPreview {
            
        @Test("when called, it is expected to load the item at the initial index only")
        func loadSelectedPhotoPreview() async throws {
            let thumbnailUrl = try Test.makeImageURL()
            let sut = sut(
                initialPhoto: NodeEntity(handle: 10),
                thumbnailUrl: thumbnailUrl)
            
            sut.loadSelectedPhotoPreview(completionHandler: nil)

            let item = try #require(sut.items.first, "First item could not be found")
            
            let result: SlideShowCellViewModel.ImageSource? = await item.value.$imageSource.values.compactMap { $0 }.first(where: { @Sendable _ in true })
            
            #expect(result?.image != nil)
            #expect(sut.items.count == 1)
        }
    }
    
    @MainActor
    @Suite("calls download from index", .timeLimit(.minutes(1)))
    struct DownloadFromIndex {
        
        static let advanceNumberOfPhotosToLoad = 3
        
        @Test("when called, it should pre load the surrounding items from the index", arguments: [
            (0, 4),
            (10, 7),
            (16, 7),
            (24, 7),
            (39, 7)
        ])
        func downloadNodesFromIndexes(currentIndex: Int, expectedNumberOfItemsAvailable: Int) async throws {
            let thumbnailUrl = try Test.makeImageURL()
            let nodes = nodeEntities
            
            let sut = sut(
                initialPhoto: NodeEntity(handle: 10),
                nodeEntities: nodes,
                thumbnailUrl: thumbnailUrl,
                advanceNumberOfPhotosToLoad: Self.advanceNumberOfPhotosToLoad)
            
            #expect(sut.items.isEmpty)
            
            sut.download(fromCurrentIndex: currentIndex)
            
            #expect(sut.items.count == expectedNumberOfItemsAvailable)
            #expect(sut.indexOfCurrentPhoto() == currentIndex)
        }
        
        @Test("when index is out of bounds, it should pre load the surrounding items from default 0 index", arguments: [-1, 50])
        func downloadNodesFromIndexesOutOfBounds(currentIndex: Int) async throws {
            let thumbnailUrl = try Test.makeImageURL()
            let nodes = nodeEntities
            
            let sut = sut(
                initialPhoto: NodeEntity(handle: 10),
                nodeEntities: nodes,
                thumbnailUrl: thumbnailUrl,
                advanceNumberOfPhotosToLoad: Self.advanceNumberOfPhotosToLoad)
            
            #expect(sut.items.isEmpty)
            
            sut.download(fromCurrentIndex: currentIndex)
                        
            let expectedNumberOfItemsAvailable = Self.advanceNumberOfPhotosToLoad + 1
            #expect(sut.items.count == expectedNumberOfItemsAvailable)
            #expect(sut.indexOfCurrentPhoto() == 0)
        }
    }

    @MainActor
    @Suite("calls Sort nodes")
    struct SortNodes {
        @Test("When calling .sortNodes() with .shuffle mode, the selected photo should be located at the beginning of the list")
        func sortNodeWithShuffled() async throws {
            let thumbnailUrl = try Test.makeImageURL()
            let sut = sut(
                initialPhoto: NodeEntity(handle: 10),
                thumbnailUrl: thumbnailUrl)

            sut.sortNodes(byOrder: .shuffled)
            #expect(sut.indexOfCurrentPhoto() == 0)
        }
    }

    nonisolated private static var nodeEntities: [NodeEntity] {
        (1...40)
            .map {
                NodeEntity(
                    name: "\($0).png",
                    handle: HandleEntity($0),
                    isFile: true,
                    modificationTime: Date(timeIntervalSince1970: Double($0)))
            }
    }
    
    @MainActor
    private static func sut(
        initialPhoto: NodeEntity? = nil,
        nodeEntities: [NodeEntity] = Self.nodeEntities,
        thumbnailUrl: URL,
        advanceNumberOfPhotosToLoad: Int = 5
    ) -> SlideShowDataSource {
        SlideShowDataSource(
            currentPhoto: initialPhoto,
            nodeEntities: nodeEntities,
            thumbnailUseCase: MockThumbnailUseCase(
                cachedThumbnails: [ThumbnailEntity(url: thumbnailUrl, type: .preview)],
                generatedCachingThumbnail: ThumbnailEntity(url: thumbnailUrl, type: .preview),
                loadPreviewResult: .success(ThumbnailEntity(url: thumbnailUrl, type: .preview))
            ),
            fileDownloadUseCase: MockFileDownloadUseCase(url: thumbnailUrl),
            mediaUseCase: MockMediaUseCase(),
            advanceNumberOfPhotosToLoad: advanceNumberOfPhotosToLoad
        )
    }
}
