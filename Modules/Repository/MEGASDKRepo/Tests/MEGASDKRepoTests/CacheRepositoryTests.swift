import Foundation
import MEGASdk
import MEGASDKRepo
import MEGASDKRepoMock
import Testing

@Suite("CacheRepository Behavior Tests")
struct CacheRepositoryTests {
    static let mockContainerPath = "/mock/container"
    static let mockOfflinePath = "/mock/offline"
    static let mockDownloadPath = "/mock/downloads"
    static let mockUploadPath = "/mock/uploads"
    static let mockGroupShared = "/mock/groupShared"
    static let testFolderName = "test"
    
    static func makeSUT(
        folderSize: UInt64 = 0,
        groupSharedSize: UInt64 = 0,
        downloadTransfers: Int = 0,
        uploadTransfers: Int = 0,
        containerURL: URL? = URL(fileURLWithPath: mockContainerPath),
        offlineURL: URL? = URL(fileURLWithPath: mockOfflinePath),
        downloadsURL: URL? = URL(fileURLWithPath: mockDownloadPath),
        uploadsURL: URL? = URL(fileURLWithPath: mockUploadPath),
        containerError: MEGAError = .init(),
        downloadsError: MEGAError = .init(),
        uploadsError: MEGAError = .init()
    ) -> (
        sut: CacheRepository,
        directoryCleaner: MockDirectoryCleaner
    ) {
        let directoryProvider = MockDirectoryProvider(
            containerURL: containerURL,
            offlineURL: offlineURL,
            downloadsURL: downloadsURL,
            uploadsURL: uploadsURL,
            containerError: containerError,
            downloadsError: downloadsError,
            uploadsError: uploadsError
        )
        
        let folderCalculator = MockFolderSizeCalculator(
            folderSize: folderSize,
            groupSharedDirectorySize: groupSharedSize
        )
        
        let cleaner = MockDirectoryCleaner()
        let sdk = MockSdk(
            transferList: MockTransferList(transfers: [])
        )
        
        let sut = CacheRepository(
            directoryProvider: directoryProvider,
            folderSizeCalculator: folderCalculator,
            directoryCleaner: cleaner,
            sdk: sdk
        )
        return (sut, cleaner)
    }

    // MARK: - Cache Size Tests
    @Suite("CacheRepository - cacheSize() Behavior")
    struct CacheSizeTests {
        
        @Test("Calculates total cache size by summing cache + temp + group shared directory")
        func calculatesTotalCacheSizeCorrectly() throws {
            let expectedSize = 1024 * 2 + 2048
            let (sut, _) = makeSUT(
                folderSize: 1024,
                groupSharedSize: 2048
            )
            let size = try sut.cacheSize()
           
            #expect(size == expectedSize)
        }
        
        @Test("Return 0 when containerURL is nil")
        func throwsWhenContainerURLIsNil() throws {
            let expectedError = MEGAError()
            let (sut, _) = makeSUT(containerError: expectedError)
            
            let size = try sut.cacheSize()
           
            #expect(size == 0)
        }
    }

    // MARK: - Cache Cleanup Tests
    @Suite("CacheRepository - cleanCache() Behavior")
    struct CleanCacheTests {
        
        @Test("Does nothing if the cache size is 0")
        func doesNothingIfCacheSizeIsZero() async throws {
            let (sut, cleaner) = makeSUT(
                folderSize: 0,
                groupSharedSize: 0
            )
            
            try await sut.cleanCache()
            
            #expect(cleaner.removeFolderContents_calledTimes == 0)
            #expect(cleaner.removeFolderContentsRecursively_calledTimes == 0)
            #expect(cleaner.removeItemAtURL_calledTimes == 0)
        }
        
        @Test("Cleans cache when size is greater than zero")
        func cleansCacheIfSizeIsNonZero() async throws {
            let (sut, cleaner) = makeSUT(
                folderSize: 500,
                groupSharedSize: 0
            )
            
            try await sut.cleanCache()
            
            #expect(cleaner.removeFolderContents_calledTimes >= 2)
        }
    }

    // MARK: - MockDirectoryProvider Behavior Tests
    @Suite("MockDirectoryProvider Behavior")
    struct MockDirectoryProviderTests {
        
        @Test("Returns the expected container URL when available")
        func returnsContainerURLWhenAvailable() throws {
            let expectedURL = URL(fileURLWithPath: mockContainerPath)
            let expectedLastPathComponent = testFolderName
            let provider = MockDirectoryProvider(containerURL: expectedURL)

            let result = try provider.urlForSharedSandboxCacheDirectory(expectedLastPathComponent)

            #expect(result.lastPathComponent == expectedLastPathComponent)
        }

        @Test("Throws error when container URL is nil")
        func throwsErrorWhenContainerURLIsNil() {
            let provider = MockDirectoryProvider()

            #expect(throws: NSError.self, performing: {
                _ = try provider.urlForSharedSandboxCacheDirectory(testFolderName)
            })
        }

        @Test("Returns the expected offline directory when available")
        func returnsOfflineDirectoryWhenAvailable() {
            let expectedURL = URL(fileURLWithPath: mockOfflinePath)
            let provider = MockDirectoryProvider(offlineURL: expectedURL)

            let result = provider.pathForOffline()

            #expect(result == expectedURL)
        }

        @Test("Returns nil when offline directory is not available")
        func returnsNilWhenOfflineDirectoryIsNotAvailable() {
            let provider = MockDirectoryProvider(offlineURL: nil)

            let result = provider.pathForOffline()

            #expect(result == nil)
        }

        @Test("Returns expected downloads directory when available")
        func returnsDownloadsDirectoryWhenAvailable() throws {
            let expectedURL = URL(fileURLWithPath: mockDownloadPath)
            let provider = MockDirectoryProvider(downloadsURL: expectedURL)

            let result = try provider.downloadsDirectory()

            #expect(result == expectedURL)
        }

        @Test("Throws error when downloads directory is nil")
        func throwsErrorWhenDownloadsDirectoryIsNil() {
            let provider = MockDirectoryProvider(downloadsURL: nil)

            #expect(throws: NSError.self, performing: {
                _ = try provider.downloadsDirectory()
            })
        }

        @Test("Returns expected uploads directory when available")
        func returnsUploadsDirectoryWhenAvailable() throws {
            let expectedURL = URL(fileURLWithPath: mockUploadPath)
            let provider = MockDirectoryProvider(uploadsURL: expectedURL)

            let result = try provider.uploadsDirectory()

            #expect(result == expectedURL)
        }

        @Test("Throws error when uploads directory is nil")
        func throwsErrorWhenUploadsDirectoryIsNil() {
            let provider = MockDirectoryProvider()

            #expect(throws: NSError.self, performing: {
                _ = try provider.uploadsDirectory()
            })
        }

        @Test("Returns expected group shared directory when available")
        func returnsGroupSharedDirectoryWhenAvailable() {
            let expectedURL = URL(fileURLWithPath: mockGroupShared)
            let provider = MockDirectoryProvider(sharedURL: expectedURL)

            let result = provider.groupSharedURL()

            #expect(result == expectedURL)
        }

        @Test("Returns nil when group shared directory is not available")
        func returnsNilWhenGroupSharedDirectoryIsNotAvailable() {
            let provider = MockDirectoryProvider()
            let result = provider.groupSharedURL()

            #expect(result == nil)
        }
    }
}
