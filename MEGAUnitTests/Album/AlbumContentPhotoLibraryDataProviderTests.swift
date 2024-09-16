@testable import MEGA
import MEGADomain
import MEGATest
import XCTest

final class AlbumContentPhotoLibraryDataProviderTests: XCTestCase {
    
    func testUpdatePhotos_newPhotosProvided_shouldUpdate() async {
        let newPhotos = [AlbumPhotoEntity(photo: NodeEntity(handle: 1), albumPhotoId: 1)]
        let sut = makeSUT()
        
        await sut.updatePhotos(newPhotos)
        
        let photos = await sut.photos(for: .allMedia)
        XCTAssertEqual(photos, newPhotos.map(\.photo))
    }
    
    func testIsEmpty_newPhotosProvided_shouldUpdate() async {
        for photos in [[AlbumPhotoEntity(photo: NodeEntity(handle: 1), albumPhotoId: 1)], []] {
            let sut = await makeSUT(photos: photos)
            
            let isEmpty = await sut.isEmpty()
            
            XCTAssertEqual(isEmpty, photos.isEmpty, "Expected empty for photo count \(photos.count)")
        }
    }
    
    func testIsFilterEnabled_photos_shouldReturnCorrectEnabledState() async {
        let image = AlbumPhotoEntity(photo: NodeEntity(name: "test.jpg", handle: 1))
        let video = AlbumPhotoEntity(photo: NodeEntity(name: "video.mp4", handle: 2))
        
        let testCase = [
            (photos: [image], filter: FilterType.images, expected: true),
            (photos: [video, image], filter: FilterType.images, expected: true),
            (photos: [video], filter: FilterType.images, expected: false),
            (photos: [], filter: FilterType.images, expected: false),
            (photos: [video], filter: FilterType.videos, expected: true),
            (photos: [image, video], filter: FilterType.videos, expected: true),
            (photos: [], filter: FilterType.videos, expected: false),
            (photos: [image], filter: FilterType.videos, expected: false),
            (photos: [image, video], filter: FilterType.allMedia, expected: true),
            (photos: [], filter: FilterType.allMedia, expected: false),
            (photos: [image], filter: FilterType.allMedia, expected: false),
            (photos: [video], filter: FilterType.allMedia, expected: false),
            (photos: [image, video], filter: FilterType.allMedia, expected: true)
        ]
        
        for (photos, filter, expected) in testCase {
            let sut = await makeSUT(photos: photos)
            
            let isEnabled = await sut.isFilterEnabled(for: filter)
            
            XCTAssertEqual(isEnabled, expected, "Expected enabled for filter \(filter) photos: \(photos)")
        }
    }
    
    func testPhotosForFilter_containsPhotoForType_shouldReturnNodes() async {
        let imageNode = NodeEntity(name: "test.jpg", handle: 1)
        let image = AlbumPhotoEntity(photo: imageNode)
        let videoNode = NodeEntity(name: "video.mp4", handle: 2)
        let video = AlbumPhotoEntity(photo: videoNode)
        
        let allPhotos = [image, video]
        let testCase = [
            (filter: FilterType.images, nodes: [imageNode]),
            (filter: FilterType.videos, nodes: [videoNode]),
            (filter: FilterType.allMedia, nodes: [imageNode, videoNode])
        ]
        
        for (filter, expectedNodes) in testCase {
            let sut = await makeSUT(photos: allPhotos)
            
            let nodes = await sut.photos(for: filter)
            
            XCTAssertEqual(nodes, expectedNodes, "Expected nodes for filter \(filter)")
        }
    }
    
    func testContainsImageAndVideo_photos_shouldReturnTrueOnlyIfItContainsImageAndVideo() async {
        let image = AlbumPhotoEntity(photo: NodeEntity(name: "test.jpg", handle: 1))
        let video = AlbumPhotoEntity(photo: NodeEntity(name: "video.mp4", handle: 2))
        
        let testCase = [
            (photos: [image, video], expected: true),
            (photos: [image], expected: false),
            (photos: [video], expected: false)
        ]
        
        for (photos, expected) in testCase {
            let sut = await makeSUT(photos: photos)
            
            let containsImageAndVideo = await sut.containsImageAndVideo()
            
            XCTAssertEqual(containsImageAndVideo, expected, "Wrong containsImageAndVideo for \(photos)")
        }
    }
    
    func testNodesToAddToAlbum_photos_shouldReturnNodesNotAlreadyInAlbumToAdd() async {
        let imageNode = NodeEntity(name: "test.jpg", handle: 1)
        let image = AlbumPhotoEntity(photo: imageNode)
        let videoNode = NodeEntity(name: "video.mp4", handle: 2)
        let video = AlbumPhotoEntity(photo: videoNode)
        
        let testCase = [
            (wantToAdd: [imageNode], currentPhotos: [video], expectedToAdd: [imageNode]),
            (wantToAdd: [videoNode], currentPhotos: [image], expectedToAdd: [videoNode]),
            (wantToAdd: [imageNode, videoNode], currentPhotos: [image, video], expectedToAdd: []),
            (wantToAdd: [imageNode, videoNode], currentPhotos: [], expectedToAdd: [imageNode, videoNode])
        ]
        
        for (wantToAdd, currentPhotos, expectedToAdd) in testCase {
            let sut = await makeSUT(photos: currentPhotos)
            
            let result = await sut.nodesToAddToAlbum(wantToAdd)
            
            XCTAssertEqual(result, expectedToAdd,
                           "Expected to add \(expectedToAdd) to for current photos \(currentPhotos)")
        }
    }
    
    func testAlbumPhotosToDelete_photos_shouldReturnPhotosToDelete() async {
        let imageNode = NodeEntity(name: "test.jpg", handle: 1)
        let image = AlbumPhotoEntity(photo: imageNode, albumPhotoId: 1)
        let videoNode = NodeEntity(name: "video.mp4", handle: 2)
        let video = AlbumPhotoEntity(photo: videoNode, albumPhotoId: 2)
        
        let allPhotos = [image, video]
        let testCase = [
            (photoNodes: [imageNode], expected: [image]),
            (photoNodes: [videoNode], expected: [video]),
            (photoNodes: [imageNode, videoNode], expected: allPhotos),
            (photoNodes: [], expected: [])
        ]
        
        for (photoNodes, expectedPhotos) in testCase {
            let sut = await makeSUT(photos: allPhotos)
            
            let photos = await sut.albumPhotosToDelete(from: photoNodes)
            
            XCTAssertEqual(photos, expectedPhotos, "Expected photos to delete for \(photoNodes)")
        }
    }

    private func makeSUT(
        photos: [AlbumPhotoEntity],
        file: StaticString = #file,
        line: UInt = #line
    ) async -> AlbumContentPhotoLibraryDataProvider {
        let sut = makeSUT()
        await sut.updatePhotos(photos)
        return sut
    }
    
    private func makeSUT(
        file: StaticString = #file,
        line: UInt = #line
    ) -> AlbumContentPhotoLibraryDataProvider {
        let sut = AlbumContentPhotoLibraryDataProvider()
        trackForMemoryLeaks(on: sut, file: file, line: line)
        return sut
    }
}
