import MEGADomain
import MEGADomainMock
import Testing

@testable import Settings

@MainActor
@Suite("FileManagementViewModel Tests")
struct FileManagementViewModelTests {
    static let cacheSize: UInt64 = 1024
    static let offlineSize: UInt64 = 2048
    static let formattedEmptySize = "Zero KB"
    
    private static func makeSUT(
        cacheSize: UInt64 = 0,
        offlineSize: UInt64 = 0,
        isMobileDataEnabled: Bool = false
    ) -> FileManagementViewModel {
        let cacheUseCase = MockCacheUseCase(cacheSize: cacheSize)
        let offlineUseCase = MockOfflineUseCase(offlineSize: offlineSize)
        let mobileDataUseCase = MockMobileDataUseCase(isEnabled: isMobileDataEnabled)
        
        return FileManagementViewModel(
            cacheUseCase: cacheUseCase,
            offlineUseCase: offlineUseCase,
            mobileDataUseCase: mobileDataUseCase,
            fileVersionsUseCase: MockFileVersionsUseCase(),
            accountUseCase: MockAccountUseCase(),
            removeOfflineFilesCompletion: {},
            navigateToRubbishBinSettings: {},
            navigateToFileVersioning: {}
        )
    }
    
    @MainActor @Suite("Setup Tests")
    struct SetupTests {
        @Test("SetupFileManagement initializes properties correctly")
        func setupFileManagement_initializesPropertiesCorrectly() {
            let sut = makeSUT(
                cacheSize: cacheSize,
                offlineSize: offlineSize,
                isMobileDataEnabled: true
            )
            
            sut.setupFileManagement()
            
            #expect(sut.formattedCacheSize == "1 KB")
            #expect(sut.formattedOfflineFilesSize == "2 KB")
            #expect(sut.isMobileDataEnabled == true)
        }
    }
    
    @MainActor @Suite("Mobile Data Tests")
    struct MobileDataTests {
        @Test("ToggleMobileDataUsage toggles correctly", arguments: [true, false])
        func toggleMobileDataUsage_togglesCorrectly(from initialState: Bool) {
            let sut = makeSUT(isMobileDataEnabled: initialState)
            
            sut.toggleMobileDataUsage(isCurrentlyEnabled: initialState)
            
            #expect(sut.isMobileDataEnabled == !initialState, "Expected isMobileDataEnabled to be toggled")
        }
    }
    
    @MainActor @Suite("Cache Management Tests")
    struct CacheTests {
        @Test("ClearCache calls use case and updates cache size", arguments: [0, 1024])
        func clearCache_callsUseCaseAndUpdatesCacheSize(for initialCacheSize: UInt64) async throws {
            let sut = makeSUT(cacheSize: initialCacheSize)
            sut.onTapClearCache()
            
            await sut.clearCacheTask?.value
            
            #expect(sut.formattedCacheSize == formattedEmptySize)
        }
    }
    
    @MainActor @Suite("Offline Files Tests")
    struct OfflineFilesTests {
        @Test("HasOfflineFiles returns correct value", arguments: [0, 2048])
        func hasOfflineFiles_returnsCorrectValue(for offlineFilesSize: UInt64) {
            let sut = makeSUT(offlineSize: offlineFilesSize)
            #expect(sut.hasOfflineFiles() == (offlineFilesSize > 0))
        }
        
        @Test("OnTapClearOfflineFiles shows alert when files exist", arguments: [0, 2048])
        func onTapClearOfflineFiles_showsAlertWhenFilesExist(for offlineFilesSize: UInt64) async {
            let sut = makeSUT(offlineSize: offlineFilesSize)
            sut.onTapClearOfflineFiles()
            
            await sut.clearOfflineFilesTask?.value
            
            #expect(sut.showClearOfflineFilesAlert == (offlineFilesSize > 0))
        }
        
        @Test("ClearOfflineFiles removes files and updates size")
        func clearOfflineFiles_removesFilesAndUpdatesSize() async {
            let sut = makeSUT(offlineSize: offlineSize)
            
            sut.clearOfflineFiles()
            
            await sut.clearOfflineFilesTask?.value
            let formattedOfflineFilesSize = sut.formattedOfflineFilesSize
            
            #expect(formattedOfflineFilesSize == formattedEmptySize)
        }
    }
}
