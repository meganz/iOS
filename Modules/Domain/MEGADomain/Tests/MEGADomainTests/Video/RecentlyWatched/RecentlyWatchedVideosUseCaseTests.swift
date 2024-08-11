import MEGADomain
import MEGADomainMock
import MEGATest
import XCTest

final class RecentlyWatchedVideosUseCaseTests: XCTestCase {
    
    // MARK: - init
    
    func testInit_whenInit_doesNotPerformAnyRequest() {
        let (_, recentlyWatchedVideosRepository) = makeSUT()
        
        XCTAssertTrue(recentlyWatchedVideosRepository.messages.isEmpty)
    }
    
    // MARK: - loadVideos
    
    func testLoadVideos_whenCalled_requestLoadVideos() async {
        let (sut, recentlyWatchedVideosRepository) = makeSUT()
        
        _ = try? await sut.loadVideos()
        
        XCTAssertEqual(recentlyWatchedVideosRepository.messages, [ .loadVideos ])
    }
    
    func testLoadVideos_whenCalledWithError_deliversError() async {
        let (sut, _) = makeSUT(
            recentlyWatchedVideosRepository: MockRecentlyWatchedVideosRepository(loadVideosResult: .failure(GenericErrorEntity()))
        )
        
        var receivedError: Error?
        do {
            _ = try await sut.loadVideos()
            XCTFail("Expect to not success loadVideos()")
        } catch {
            receivedError = error
        }
        
        XCTAssertNotNil(receivedError)
    }
    
    func testLoadVideos_whenCalledSuccessfully_deliversEmptyItems() async throws {
        let emptyItems: [RecentlyWatchedVideoEntity] = []
        let (sut, _) = makeSUT(
            recentlyWatchedVideosRepository: MockRecentlyWatchedVideosRepository(loadVideosResult: .success(emptyItems))
        )
        
        let receivedItems = try await sut.loadVideos()
        
        XCTAssertEqual(emptyItems, receivedItems)
    }
    
    func testLoadVideos_whenCalledSuccessfully_deliversSingleItems() async throws {
        let singleItems: [RecentlyWatchedVideoEntity] = [
            RecentlyWatchedVideoEntity(
                video: nodeEntity(handle: 1),
                lastWatchedDate: nil,
                lastWatchedTimestamp: Date()
            )
        ]
        let (sut, _) = makeSUT(
            recentlyWatchedVideosRepository: MockRecentlyWatchedVideosRepository(loadVideosResult: .success(singleItems))
        )
        
        let receivedItems = try await sut.loadVideos()
        
        XCTAssertEqual(singleItems, receivedItems)
    }
    
    func testLoadVideos_whenCalledSuccessfully_deliversMoreThanOneItems() async throws {
        let items: [RecentlyWatchedVideoEntity] = [
            RecentlyWatchedVideoEntity(
                video: nodeEntity(handle: 1),
                lastWatchedDate: nil,
                lastWatchedTimestamp: Date()
            ),
            RecentlyWatchedVideoEntity(
                video: nodeEntity(handle: 2),
                lastWatchedDate: nil,
                lastWatchedTimestamp: Date()
            )
        ]
        let (sut, _) = makeSUT(
            recentlyWatchedVideosRepository: MockRecentlyWatchedVideosRepository(loadVideosResult: .success(items))
        )
        
        let receivedItems = try await sut.loadVideos()
        
        XCTAssertEqual(items, receivedItems)
    }
    
    // MARK: - clearVideos
    
    func testClearVideos_whenCalled_requestClearVideos() {
        let (sut, recentlyWatchedVideosRepository) = makeSUT()
        
        _ = try? sut.clearVideos()
        
        XCTAssertEqual(recentlyWatchedVideosRepository.messages, [ .clearVideos ])
    }
    
    func testClearVideos_whenCalledWithError_deliversError() {
        let (sut, _) = makeSUT(
            recentlyWatchedVideosRepository: MockRecentlyWatchedVideosRepository(clearVideosResult: .failure(GenericErrorEntity()))
        )
        
        var receivedError: Error?
        do {
            try sut.clearVideos()
            XCTFail("Expect to throw error, but got no error instead")
        } catch {
            receivedError = error
        }
        
        XCTAssertNotNil(receivedError)
    }
    
    func testClearVideos_whenCalledSuccessfully_doesNotThrowError() throws {
        let (sut, _) = makeSUT(
            recentlyWatchedVideosRepository: MockRecentlyWatchedVideosRepository(clearVideosResult: .success(()))
        )
        
        try sut.clearVideos()
    }
    
    // MARK: - saveVideo
    
    func testSaveVideo_whenCalled_performSaveVideo() {
        let (sut, recentlyWatchedVideosRepository) = makeSUT(
            recentlyWatchedVideosRepository: MockRecentlyWatchedVideosRepository()
        )
        let recentlyWatchedVideoEntity = RecentlyWatchedVideoEntity(
            video: nodeEntity(handle: 1),
            lastWatchedDate: nil,
            lastWatchedTimestamp: Date()
        )
        
        try? sut.saveVideo(recentlyWatchedVideo: recentlyWatchedVideoEntity)
        
        XCTAssertEqual(recentlyWatchedVideosRepository.messages, [ .saveVideo(recentlyWatchedVideoEntity) ])
    }
    
    func testSaveVideo_whenCalledWithError_canThrowError() {
        let (sut, _) = makeSUT(
            recentlyWatchedVideosRepository: MockRecentlyWatchedVideosRepository(saveVideoResult: .failure(GenericErrorEntity()))
        )
        let recentlyWatchedVideoEntity = RecentlyWatchedVideoEntity(
            video: nodeEntity(handle: 1),
            lastWatchedDate: nil,
            lastWatchedTimestamp: Date()
        )
        
        var receivedError: Error?
        do {
            try sut.saveVideo(recentlyWatchedVideo: recentlyWatchedVideoEntity)
            XCTFail("expect to throw error, but not throwing error instead.")
        } catch {
            receivedError = error
        }
        
        XCTAssertNotNil(receivedError)
    }
    
    func testSaveVideo_whenCalledSuccessfully_doesNotThrowError() throws {
        let (sut, _) = makeSUT(
            recentlyWatchedVideosRepository: MockRecentlyWatchedVideosRepository(saveVideoResult: .success(()))
        )
        let recentlyWatchedVideoEntity = RecentlyWatchedVideoEntity(
            video: nodeEntity(handle: 1),
            lastWatchedDate: nil,
            lastWatchedTimestamp: Date()
        )
        
        try sut.saveVideo(recentlyWatchedVideo: recentlyWatchedVideoEntity)
    }
    
    // MARK: - Helpers
    
    private func makeSUT(
        recentlyWatchedVideosRepository: MockRecentlyWatchedVideosRepository = MockRecentlyWatchedVideosRepository()
    ) -> (
        sut: RecentlyWatchedVideosUseCase,
        recentlyWatchedVideosRepository: MockRecentlyWatchedVideosRepository
    ) {
        let sut = RecentlyWatchedVideosUseCase(recentlyWatchedVideosRepository: recentlyWatchedVideosRepository)
        return (sut, recentlyWatchedVideosRepository)
    }
    
    private func nodeEntity(handle: HandleEntity) -> NodeEntity {
        NodeEntity(name: "any-video-\(handle).mp4", handle: handle)
    }
    
}
