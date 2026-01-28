@testable import ContentLibraries
import MEGAAnalyticsiOS
import MEGAAppPresentation
import MEGAAppPresentationMock
import MEGADomain
import Testing

struct PhotoLibraryContentViewModelTests {
    @MainActor
    @Test(arguments: [
        (PhotoLibraryContentMode.album, false),
        (.albumLink, false),
        (.library, true),
        (.mediaDiscovery, true),
        (.mediaDiscoveryFolderLink, true),
    ])
    func shouldShowPhotoLibraryPicker(mode: PhotoLibraryContentMode, expectedResult: Bool) {
        let sut = Self.makeSUT(contentMode: mode)
        #expect(sut.shouldShowPhotoLibraryPicker == expectedResult)
    }
    
    @MainActor
    @Test
    func testToggleSelectAllPhotos_onCalledAgain_shouldToggleBetweenSelectAllAndUnselectAll() throws {
        let photos = [NodeEntity(name: "a.png", handle: HandleEntity(1),
                                 modificationTime: try "2023-08-18T22:01:04Z".date),
                      NodeEntity(name: "b.png", handle: HandleEntity(2),
                                 modificationTime: try "2023-08-11T22:01:04Z".date)
        ]
        let library = photos.toPhotoLibrary(withSortType: .modificationDesc)
        let sut = Self.makeSUT(library: library, contentMode: .album)
        
        sut.toggleSelectAllPhotos()
        
        #expect(sut.selection.allSelected)
        #expect(Set(library.allPhotos) == Set(photos))
        
        sut.toggleSelectAllPhotos()
        
        #expect(sut.selection.allSelected == false)
        #expect(sut.selection.photos.isEmpty)
        #expect(library.allPhotos.isNotEmpty)
    }
    
    @MainActor
    @Test(arguments: [
        [NodeEntity(name: "a.png", handle: HandleEntity(1), modificationTime: try "2023-08-18T22:01:04Z".date)],
        []
    ])
    func testIsPhotoLibraryEmpty_onPhotoLibraryContentChange_shouldReturnPhotoLibraryEmptyState(photos: [NodeEntity]) throws {
        let sut = Self.makeSUT(library: photos.toPhotoLibrary(withSortType: .modificationDesc))
        
        #expect(sut.isPhotoLibraryEmpty ==  photos.isEmpty)
    }
    
    @MainActor
    @Test
    func libraryViewModeChangeTrackAnalytics() {
        let tracker = MockTracker()
        let sut = Self.makeSUT(
            tracker: tracker)
        
        sut.selectedMode = .day
        sut.selectedMode = .month
        sut.selectedMode = .year
        sut.selectedMode = .all
        
        Test.assertTrackAnalyticsEventCalled(
            trackedEventIdentifiers: tracker.trackedEventIdentifiers,
            with: [
                MediaScreenDaysFilterSelectedEvent(),
                MediaScreenMonthsFilterSelectedEvent(),
                MediaScreenYearsFilterSelectedEvent(),
                MediaScreenAllFilterSelectedEvent()
            ]
        )
    }
    
    @MainActor
    private static func makeSUT(
        library: PhotoLibrary = PhotoLibrary(),
        contentMode: PhotoLibraryContentMode = .library,
        configuration: PhotoLibraryContentConfiguration? = nil,
        tracker: some AnalyticsTracking = MockTracker()
    ) -> PhotoLibraryContentViewModel {
        .init(
            library: library,
            contentMode: contentMode,
            configuration: configuration,
            tracker: tracker
        )
    }
}
