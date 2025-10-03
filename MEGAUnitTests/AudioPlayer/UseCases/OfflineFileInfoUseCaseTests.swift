@testable import MEGA
import Testing

@Suite("OfflineFileInfoUseCase")
struct OfflineFileInfoUseCaseTests {
    private static func makeSUT(repo: MockOfflineInfoRepository) -> OfflineFileInfoUseCase {
        OfflineFileInfoUseCase(offlineInfoRepository: repo)
    }
    
    @Suite("Fetch tracks from file paths")
    struct FetchTracksSuite {
        @Test(arguments: [
            (MockOfflineInfoRepository(result: .success), ["a.mp3", "b.m4a"], Comment("success with multiple files returns items")),
            (MockOfflineInfoRepository(result: .success), ["a.mp3"], Comment("success with single file returns items")),
            (MockOfflineInfoRepository(result: .failure(.generic)), ["a.mp3"], Comment("failure returns nil items"))
        ])
        func fetchTracks_returnsItemsOnSuccess_elseNil(_ repo: MockOfflineInfoRepository, _ files: [String], _ note: Comment) {
            let sut = makeSUT(repo: repo)
            let items = sut.fetchTracks(from: files)
            if case .success = repo.result {
                #expect(items?.count == AudioPlayerItem.mockArray.count, note)
                #expect(items?.compactMap(\.url) == AudioPlayerItem.mockArray.compactMap(\.url))
            } else {
                #expect(items == nil, note)
            }
        }
    }
    
    @Suite("Edge cases")
    struct EdgeCasesSuite {
        @Test(arguments: [
            (MockOfflineInfoRepository(result: .success), Optional<[String]>.none, Comment("nil input mirrors repository: success returns items")),
            (MockOfflineInfoRepository(result: .failure(.generic)), Optional<[String]>.none, Comment("nil input mirrors repository: failure returns nil"))
        ])
        func fetchTracks_handlesNilInput(_ repo: MockOfflineInfoRepository, _ files: [String]?, _ note: Comment) {
            let sut = makeSUT(repo: repo)
            let items = sut.fetchTracks(from: files)
            if case .success = repo.result {
                #expect(items?.count == AudioPlayerItem.mockArray.count, note)
                #expect(items?.compactMap(\.url) == AudioPlayerItem.mockArray.compactMap(\.url))
            } else {
                #expect(items == nil, note)
            }
        }
        
        @Test(arguments: [
            (MockOfflineInfoRepository(result: .success), [String](), Comment("empty list mirrors repository: success returns items")),
            (MockOfflineInfoRepository(result: .failure(.generic)), [String](), Comment("empty list mirrors repository: failure returns nil"))
        ])
        func fetchTracks_handlesEmptyList(_ repo: MockOfflineInfoRepository, _ files: [String], _ note: Comment) {
            let sut = makeSUT(repo: repo)
            let items = sut.fetchTracks(from: files)
            if case .success = repo.result {
                #expect(items?.count == AudioPlayerItem.mockArray.count, note)
                #expect(items?.compactMap(\.url) == AudioPlayerItem.mockArray.compactMap(\.url))
            } else {
                #expect(items == nil, note)
            }
        }
    }
}
