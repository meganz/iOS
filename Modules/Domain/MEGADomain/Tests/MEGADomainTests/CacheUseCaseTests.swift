import MEGADomain
import MEGADomainMock
import Testing

@Suite("CacheUseCaseTests")
struct CacheUseCaseTests {
    private static let nonZeroFolderSizes: [String: UInt64] = [
        "cache": 1024,
        "temp": 2048,
        "group": 4096
    ]
    private static let zeroFolderSizes: [String: UInt64] = [
        "cache": 0,
        "temp": 0,
        "group": 0
    ]
    
    private static func makeSUT(
        folderSizes: [String: UInt64] = [:],
        uploadTransfersSize: Int = 1
    ) -> (sut: CacheUseCase, mockRepo: MockCacheRepository) {
        let mockRepo = MockCacheRepository(folderSizes: folderSizes)
        let sut = CacheUseCase(cacheRepository: mockRepo)
        return (sut, mockRepo)
    }

    @Suite("Cache size tests")
    struct CacheSizeTests {
        @Test("Calculates cache size using repository")
        func calculatesCacheSizeUsingRepository() throws {
            let (sut, mockRepo) = makeSUT(folderSizes: nonZeroFolderSizes)
            let expectedSize = nonZeroFolderSizes.values.reduce(0, +)
            
            let size = try sut.cacheSize()
            
            #expect(size == expectedSize)
            #expect(mockRepo.cacheSize_calledTimes == 1)
        }
        
        @Test("Does not calculate cache size if folder sizes are zero")
        func doesNotCalculateCacheSizeIfFolderSizesAreZero() throws {
            let (sut, mockRepo) = makeSUT(folderSizes: zeroFolderSizes)
            let expectedSize = 0
            
            let size = try sut.cacheSize()
            
            #expect(size == expectedSize)
            #expect(mockRepo.cacheSize_calledTimes == 1)
        }
    }

    @Suite("Cache cleaning tests")
    struct CacheCleaningTests {
        @Test("Does not clean cache if size is zero")
        func doesNotCleanCacheIfSizeIsZero() async throws {
            let (sut, mockRepo) = makeSUT(folderSizes: zeroFolderSizes)
            
            try await sut.cleanCache()
            
            #expect(mockRepo.cleanCache_calledTimes == 1)
            #expect(mockRepo.didCleanCache == false)
        }

        @Test("Cleans cache when size is greater than zero")
        func cleansCacheWhenSizeIsGreaterThanZero() async throws {
            let (sut, mockRepo) = makeSUT(folderSizes: nonZeroFolderSizes)
            
            try await sut.cleanCache()
            
            #expect(mockRepo.cleanCache_calledTimes == 1)
            #expect(mockRepo.didCleanCache == true)
        }
    }
}
