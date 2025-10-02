@testable import MEGA
import MEGADomain
import Testing

@Suite("StreamingInfoUseCase")
struct StreamingInfoUseCaseTests {
    static let successRepo = MockStreamingInfoRepository(result: .success)
    static let failureRepo = MockStreamingInfoRepository(result: .failure(.generic))
    
    @Suite("Info")
    struct InfoSuite {
        @Test("returns item on success and nil on failure")
        func infoFromFolderLinkNode() throws {
            let item = try #require(StreamingInfoUseCaseTests.successRepo.fetchTrack(from: MEGANode()))
            let expected = AudioPlayerItem.mockItem
            #expect(item.url == expected.url)
            #expect(StreamingInfoUseCaseTests.failureRepo.fetchTrack(from: MEGANode()) == nil)
        }
    }
    
    @Suite("Path")
    struct PathSuite {
        @Test("returns path on success and nil on failure")
        func pathFromNode() throws {
            let path = try #require(StreamingInfoUseCaseTests.successRepo.streamingURL(for: MEGANode()))
            let expected = AudioPlayerItem.mockItem.url
            #expect(path == expected)
            #expect(StreamingInfoUseCaseTests.failureRepo.streamingURL(for: MEGANode()) == nil)
        }
    }
}
