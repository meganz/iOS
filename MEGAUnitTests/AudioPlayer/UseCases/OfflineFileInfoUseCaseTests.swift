@testable import MEGA
import Testing

@Suite("OfflineFileInfoUseCase")
struct OfflineFileInfoUseCaseTests {
    static let successRepo = MockOfflineInfoRepository(result: .success)
    static let failureRepo = MockOfflineInfoRepository(result: .failure(.generic))
    
    @Suite("InfoFromFiles")
    struct InfoFromFilesSuite {
        @Test("returns items on success and nil on failure")
        func infoFromFiles() throws {
            let items = try #require(OfflineFileInfoUseCaseTests.successRepo.info(fromFiles: [""]))
            let expected = AudioPlayerItem.mockArray
            #expect(items.compactMap(\.url) == expected.compactMap(\.url))
            #expect(OfflineFileInfoUseCaseTests.failureRepo.info(fromFiles: [""]) == nil)
        }
    }
    
    @Suite("LocalPath")
    struct LocalPathSuite {
        @Test("returns local path on success and nil on failure")
        func localPathFromNode() throws {
            let path = try #require(OfflineFileInfoUseCaseTests.successRepo.localPath(fromNode: MEGANode()))
            let expected = AudioPlayerItem.mockItem.url
            #expect(path == expected)
            #expect(OfflineFileInfoUseCaseTests.failureRepo.localPath(fromNode: MEGANode()) == nil)
        }
    }
}
