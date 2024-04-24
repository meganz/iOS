@testable import MEGADomain
import MEGADomainMock
import XCTest

final class VideoPlaylistModificationUseCaseTests: XCTestCase {
    
    // MARK: - Init
    
    func testInit_whenCalled_doesNotExecuteUseCase() async {
        let (_, userVideoPlaylistsRepository) = makeSUT()
        
        let messages = await userVideoPlaylistsRepository.messages
        XCTAssertTrue(messages.isEmpty)
    }
    
    // MARK: - addVideoToPlaylist
    
    func testAddVideoToPlaylist_whenCalled_addVideosToVideoPlaylist() async {
        let (sut, userVideoPlaylistsRepository) = makeSUT()
        let nodesToAdd: [NodeEntity] = [ anyNode(id: 1) ]
        
        _ = try? await sut.addVideoToPlaylist(by: 1, nodes: nodesToAdd)
        
        let messages = await userVideoPlaylistsRepository.messages
        XCTAssertEqual(messages, [
            .addVideosToVideoPlaylist(id: 1, nodes: nodesToAdd)
        ])
    }
    
    func testAddVideoToPlaylist_whenCalledTwice_addVideosToVideoPlaylistTwice() async {
        let (sut, userVideoPlaylistsRepository) = makeSUT()
        let nodesToAdd: [NodeEntity] = [ anyNode(id: 1) ]
        
        _ = try? await sut.addVideoToPlaylist(by: 1, nodes: nodesToAdd)
        _ = try? await sut.addVideoToPlaylist(by: 1, nodes: nodesToAdd)
        
        let messages = await userVideoPlaylistsRepository.messages
        XCTAssertEqual(messages, [
            .addVideosToVideoPlaylist(id: 1, nodes: nodesToAdd),
            .addVideosToVideoPlaylist(id: 1, nodes: nodesToAdd)
        ])
    }
    
    func testAddVideoToPlaylist_whenCalledWithError_throwsError() async {
        let (sut, _) = makeSUT(
            addVideosToVideoPlaylistResult: .failure(GenericErrorEntity())
        )
        let nodesToAdd: [NodeEntity] = [ anyNode(id: 1) ]
        
        do {
            _ = try await sut.addVideoToPlaylist(by: 1, nodes: nodesToAdd)
            XCTFail("Expect to catch error")
        } catch {
            XCTAssertTrue(error is GenericErrorEntity)
        }
    }
    
    func testAddVideoToPlaylist_whenCalledWithSuccessResult_addVideosToPlaylist() async throws {
        let expectedResultEntity: VideoPlaylistCreateSetElementsResultEntity = [ 1 : .success(anySetEntity(handle: 1)) ]
        let (sut, _) = makeSUT(
            addVideosToVideoPlaylistResult: .success(expectedResultEntity)
        )
        let nodesToAdd: [NodeEntity] = [ anyNode(id: 1) ]
        
        let actualResultEntity = try await sut.addVideoToPlaylist(by: 1, nodes: nodesToAdd)
        
        XCTAssertEqual(VideoPlaylistElementsResultEntity(success: 1, failure: 0), actualResultEntity)
    }
    
    // MARK: - deleteVideos
    
    func testDeleteVideos_onVideoPlaylistVideoEntityWithEmptyIds_shouldNotExecuteRepository() async throws {
        let videoPlaylist = VideoPlaylistEntity(id: 1, name: "Custom", coverNode: nil, count: 1, type: .user)
        let (sut, userVideoPlaylistsRepository) = makeSUT()
        
        _ = try await sut.deleteVideos(in: videoPlaylist.id, videos: [])
        
        let messages = await userVideoPlaylistsRepository.messages
        XCTAssertTrue(messages.isEmpty, "Expect not to execute repository")
    }
    
    func testDeleteVideos_onVideoPlaylistVideoEntityWithEmptyIds_shouldReturnZeroVideoPlaylistResultEntity() async throws {
        let videoPlaylist = VideoPlaylistEntity(id: 1, name: "Custom", coverNode: nil, count: 1, type: .user)
        let (sut, _) = makeSUT()
        
        let result = try await sut.deleteVideos(in: videoPlaylist.id, videos: [])
        
        XCTAssertEqual(result.success, 0)
        XCTAssertEqual(result.failure, 0)
    }
    
    func testDeleteVideos_onVideoPlaylistVideoEntityWithNoValidIds_shouldNotExecuteDeleteVideos() async throws {
        let videoPlaylist = VideoPlaylistEntity(id: 1, name: "Custom", coverNode: nil, count: 1, type: .user)
        let videosToRemove = [ VideoPlaylistVideoEntity(video: NodeEntity(handle: 1), videoPlaylistVideoId: nil) ]
        let (sut, userVideoPlaylistsRepository) = makeSUT()
        
        _ = try await sut.deleteVideos(in: videoPlaylist.id, videos: videosToRemove)
        
        let messages = await userVideoPlaylistsRepository.messages
        XCTAssertTrue(messages.isEmpty, "Expect not to execute repository")
    }
    
    func testDeleteVideos_onVideoPlaylistVideoEntityWithNoValidIds_shouldReturnZeroVideoPlaylistResultEntity() async throws {
        let videoPlaylist = VideoPlaylistEntity(id: 1, name: "Custom", coverNode: nil, count: 1, type: .user)
        let videosToRemove = [ VideoPlaylistVideoEntity(video: NodeEntity(handle: 1), videoPlaylistVideoId: nil) ]
        let (sut, _) = makeSUT()
        
        let result = try await sut.deleteVideos(in: videoPlaylist.id, videos: videosToRemove)
        
        XCTAssertEqual(result.success, 0)
        XCTAssertEqual(result.failure, 0)
    }
    
    func testDeleteVideos_onVideoPlaylistVideoEntityWithNoValidIds_executeDeleteVideoPlaylist() async throws {
        let videoPlaylist = VideoPlaylistEntity(id: 1, name: "Custom", coverNode: nil, count: 1, type: .user)
        let videosToRemove = [
            VideoPlaylistVideoEntity(video: NodeEntity(handle: 1), videoPlaylistVideoId: 1),
            VideoPlaylistVideoEntity(video: NodeEntity(handle: 2), videoPlaylistVideoId: 2)
        ]
        let expectedVideoPlaylistResult: VideoPlaylistCreateSetElementsResultEntity = [
            1: .success(anySetEntity(handle: videosToRemove.first?.id ?? 1)),
            2: .success(anySetEntity(handle: videosToRemove.first?.id ?? 2)),
        ]
        let (sut, userVideoPlaylistsRepository) = makeSUT(deleteVideosResult: .success(expectedVideoPlaylistResult))
        
        _ = try await sut.deleteVideos(in: videoPlaylist.id, videos: videosToRemove)
        
        let messages = await userVideoPlaylistsRepository.messages
        XCTAssertEqual(messages, [ .deleteVideoPlaylistElements(videoPlaylistId: videoPlaylist.id, elementIds: videosToRemove.map { $0.id }) ])
    }
    
    func testDeleteVideos_onVideoPlaylistVideoEntityWithValidVideoIds_shouldReturnVideoPlaylistResultEntityWithIdCount() async throws {
        let videoPlaylist = VideoPlaylistEntity(id: 1, name: "Custom", coverNode: nil, count: 1, type: .user)
        let videosToRemove = [
            VideoPlaylistVideoEntity(video: NodeEntity(handle: 1), videoPlaylistVideoId: 1),
            VideoPlaylistVideoEntity(video: NodeEntity(handle: 2), videoPlaylistVideoId: 2)
        ]
        let expectedVideoPlaylistResult: VideoPlaylistCreateSetElementsResultEntity = [
            1: .success(anySetEntity(handle: videosToRemove.first?.id ?? 1)),
            2: .success(anySetEntity(handle: videosToRemove.first?.id ?? 2)),
        ]
        let (sut, _) = makeSUT(deleteVideosResult: .success(expectedVideoPlaylistResult))
        
        let result = try await sut.deleteVideos(in: videoPlaylist.id, videos: videosToRemove)
        
        XCTAssertEqual(result.success, expectedVideoPlaylistResult.successCount)
        XCTAssertEqual(result.failure, expectedVideoPlaylistResult.errorCount)
    }
    
    // MARK: - Helpers
    
    private func makeSUT(
        videoPlaylistsResult: [SetEntity] = [],
        addVideosToVideoPlaylistResult: Result<VideoPlaylistCreateSetElementsResultEntity, Error> = .failure(GenericErrorEntity()),
        deleteVideosResult: Result<VideoPlaylistCreateSetElementsResultEntity, Error> = .failure(GenericErrorEntity())
    ) -> (
        sut: VideoPlaylistModificationUseCase,
        userVideoPlaylistsRepository: MockUserVideoPlaylistsRepository
    ) {
        let userVideoPlaylistsRepository = MockUserVideoPlaylistsRepository(
            videoPlaylistsResult: videoPlaylistsResult,
            addVideosToVideoPlaylistResult: addVideosToVideoPlaylistResult,
            deleteVideosResult: deleteVideosResult
        )
        let sut = VideoPlaylistModificationUseCase(userVideoPlaylistsRepository: userVideoPlaylistsRepository)
        return (sut, userVideoPlaylistsRepository)
    }
    
    private func anySetEntity(handle: HandleEntity) -> SetEntity {
        SetEntity(handle: handle, setType: .playlist)
        
    }
    
    private func anyNode(id: HandleEntity) -> NodeEntity {
        NodeEntity(
            changeTypes: .new,
            nodeType: .file,
            name: "some-name",
            handle: id,
            isFile: true,
            hasThumbnail: true,
            hasPreview: true,
            label: .unknown,
            publicHandle: id,
            size: 2,
            duration: 2,
            mediaType: .video
        )
    }
    
}
