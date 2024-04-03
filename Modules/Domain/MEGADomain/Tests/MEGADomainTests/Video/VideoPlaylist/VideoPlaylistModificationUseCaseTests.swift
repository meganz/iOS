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
        let expectedResultEntity = VideoPlaylistElementsResultEntity(success: 1, failure: 0)
        let (sut, _) = makeSUT(
            addVideosToVideoPlaylistResult: .success(expectedResultEntity)
        )
        let nodesToAdd: [NodeEntity] = [ anyNode(id: 1) ]
        
        let actualResultEntity = try await sut.addVideoToPlaylist(by: 1, nodes: nodesToAdd)
        
        XCTAssertEqual(expectedResultEntity, actualResultEntity)
    }
    
    // MARK: - Helpers
    
    private func makeSUT(
        videoPlaylistsResult: [SetEntity] = [],
        addVideosToVideoPlaylistResult: Result<VideoPlaylistElementsResultEntity, Error> = .failure(GenericErrorEntity())
    ) -> (
        sut: VideoPlaylistModificationUseCase,
        userVideoPlaylistsRepository: MockUserVideoPlaylistsRepository
    ) {
        let userVideoPlaylistsRepository = MockUserVideoPlaylistsRepository(
            videoPlaylistsResult: videoPlaylistsResult,
            addVideosToVideoPlaylistResult: addVideosToVideoPlaylistResult
        )
        let sut = VideoPlaylistModificationUseCase(userVideoPlaylistsRepository: userVideoPlaylistsRepository)
        return (sut, userVideoPlaylistsRepository)
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
