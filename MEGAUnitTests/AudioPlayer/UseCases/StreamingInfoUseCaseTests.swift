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
            let item = try #require(StreamingInfoUseCaseTests.successRepo.info(fromFolderLinkNode: MEGANode()))
            let expected = AudioPlayerItem.mockItem
            #expect(item.url == expected.url)
            #expect(StreamingInfoUseCaseTests.failureRepo.info(fromFolderLinkNode: MEGANode()) == nil)
        }
    }
    
    @Suite("Path")
    struct PathSuite {
        @Test("returns path on success and nil on failure")
        func pathFromNode() throws {
            let path = try #require(StreamingInfoUseCaseTests.successRepo.path(fromNode: MEGANode()))
            let expected = AudioPlayerItem.mockItem.url
            #expect(path == expected)
            #expect(StreamingInfoUseCaseTests.failureRepo.path(fromNode: MEGANode()) == nil)
        }
    }
}
