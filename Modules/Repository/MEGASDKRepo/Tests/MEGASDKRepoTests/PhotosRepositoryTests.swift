import MEGADomain
import MEGASdk
import MEGASDKRepo
import MEGASDKRepoMock
import XCTest

final class PhotosRepositoryTests: XCTestCase {
    func testAllPhotos_rootNodeNotFound_shouldThrowError() async {
        let sut = makeSUT()
        do {
            _ = try await sut.allPhotos()
            XCTFail("Should have thrown error")
        } catch {
            XCTAssertEqual(error as? NodeErrorEntity, NodeErrorEntity.nodeNotFound)
        }
    }
    
    func testAllPhotos_photoSourceEmpty_shouldRetrievePhotosThroughSearch() async throws {
        let expectedPhotos = [MockNode(handle: 45),
                              MockNode(handle: 65)]
        let sdk = MockSdk(nodes: expectedPhotos,
                          megaRootNode: MockNode(handle: 1))
        let sut = makeSUT(sdk: sdk)
        
        let photos = try await sut.allPhotos()
        XCTAssertEqual(Set(photos), Set(expectedPhotos.toNodeEntities()))
    }
    
    func testAllPhotos_multipleCallsAndSourceEmpty_shouldEnsureThatSearchOnlyCalledOnceForImageAndOnceForVideos() async throws {
        
        let sdk = MockSdk(megaRootNode: MockNode(handle: 1))
        let sut = makeSUT(sdk: sdk)
        
        async let photosOne = try await sut.allPhotos()
        async let photosTwo = try await sut.allPhotos()
        
        _ = try await photosOne + photosTwo
        
        XCTAssertEqual(sdk.nodeListSearchCallCount, 2)
    }
    
    func testAllPhotos_photoSourceContainsPhotos_shouldRetrievePhotos() async throws {
        let expectedPhotos = [NodeEntity(handle: 43),
                              NodeEntity(handle: 99)
        ]
        let photoLocalSource = MockPhotoLocalSource(photos: expectedPhotos)
        let sut = makeSUT(photoLocalSource: photoLocalSource)
        
        let photos = try await sut.allPhotos()
        XCTAssertEqual(photos, expectedPhotos)
    }
    
    func testPhotoForHandle_photoSourceDontContainPhoto_shouldRetrieveAndSetPhoto() async {
        let handle = HandleEntity(5)
        let expectedNode = MockNode(handle: handle)
        let sdk = MockSdk(nodes: [expectedNode])
        let photoLocalSource = MockPhotoLocalSource()
        let sut = makeSUT(sdk: sdk,
                          photoLocalSource: photoLocalSource)
        
        let photo = await sut.photo(forHandle: handle)
        
        XCTAssertEqual(photo, expectedNode.toNodeEntity())
        let photoSourcePhotos = await photoLocalSource.photos
        XCTAssertEqual(photoSourcePhotos, [expectedNode.toNodeEntity()])
    }
    
    func testPhotoForHandle_SDKCantGetNode_shouldReturnNil() async {
        let sut = makeSUT()
        
        let photo = await sut.photo(forHandle: 6)
        
        XCTAssertNil(photo)
    }
    
    func testPhotoForHandle_photoSourceContainPhoto_shouldReturnPhoto() async {
        let handle = HandleEntity(5)
        let expectedNode = NodeEntity(handle: handle)
        let photoLocalSource = MockPhotoLocalSource(photos: [expectedNode])
        let sut = makeSUT(photoLocalSource: photoLocalSource)
        
        let photo = await sut.photo(forHandle: handle)
        
        XCTAssertEqual(photo, expectedNode)
    }
    
    private func makeSUT(sdk: MEGASdk = MockSdk(),
                         photoLocalSource: some PhotoLocalSourceProtocol = MockPhotoLocalSource()
    ) -> PhotosRepository {
        PhotosRepository(sdk: sdk,
                         photoLocalSource: photoLocalSource)
    }
}
