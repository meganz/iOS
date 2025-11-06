@testable import ContentLibraries
import UIKit
import XCTest

final class PhotoLibraryCollectionViewScrollTrackerTests: XCTestCase {
    private var delegate: MockPhotoLibraryCollectionViewScroller!
    private var libraryViewModel: PhotoLibraryContentViewModel!
    private var tracker: PhotoLibraryCollectionViewScrollTracker!

    @MainActor
    private func makeSUT() {
        delegate = MockPhotoLibraryCollectionViewScroller()
        libraryViewModel = PhotoLibraryContentViewModel(library: PhotoLibrary())
        tracker = PhotoLibraryCollectionViewScrollTracker(
            libraryViewModel: libraryViewModel,
            collectionView: UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout()),
            delegate: delegate,
            in: .GMT
        )
        tracker.startTrackingScrolls()
    }

    @MainActor
    func testScroll_noCardPositionAndNoPhotoPosition_scrollToTop() throws {
        makeSUT()
        libraryViewModel.cardScrollPosition = nil
        libraryViewModel.photoScrollPosition = nil
        
        NotificationCenter.default.post(name: .didFinishPhotoCardScrollPositionCalculation, object: nil)
        XCTAssertEqual(delegate.scrollToPosition, .top)
    }
    
    @MainActor
    func testScroll_hasCardPositionAndNoPhotoPosition_scrollToCardPosition() throws {
        makeSUT()
        let position = PhotoScrollPosition(handle: 1, date: Date())
        libraryViewModel.cardScrollPosition = position
        libraryViewModel.photoScrollPosition = nil
        
        NotificationCenter.default.post(name: .didFinishPhotoCardScrollPositionCalculation, object: nil)
        XCTAssertEqual(delegate.scrollToPosition, position)
    }
    
    @MainActor
    func testScroll_noCardPositionAndhasPhotoPosition_scrollToPhotoPosition() throws {
        makeSUT()
        let position = PhotoScrollPosition(handle: 1, date: Date())
        libraryViewModel.cardScrollPosition = nil
        libraryViewModel.photoScrollPosition = position
        
        NotificationCenter.default.post(name: .didFinishPhotoCardScrollPositionCalculation, object: nil)
        XCTAssertEqual(delegate.scrollToPosition, position)
    }
    
    @MainActor
    func testScroll_hasCardPositionAndhasPhotoPositionAndSameDay_noScroll() throws {
        makeSUT()
        libraryViewModel.cardScrollPosition = PhotoScrollPosition(handle: 1, date: try "2020-04-18T12:01:04Z".date)
        libraryViewModel.photoScrollPosition = PhotoScrollPosition(handle: 10, date: try "2020-04-18T09:41:54Z".date)
        
        NotificationCenter.default.post(name: .didFinishPhotoCardScrollPositionCalculation, object: nil)
        XCTAssertNil(delegate.scrollToPosition)
    }
    
    @MainActor
    func testScroll_hasCardPositionAndhasPhotoPositionAndDifferentDay_scrollToCardPosition() throws {
        makeSUT()
        libraryViewModel.cardScrollPosition = PhotoScrollPosition(handle: 1, date: try "2020-09-13T12:01:04Z".date)
        libraryViewModel.photoScrollPosition = PhotoScrollPosition(handle: 10, date: try "2020-04-18T09:41:54Z".date)
        
        NotificationCenter.default.post(name: .didFinishPhotoCardScrollPositionCalculation, object: nil)
        XCTAssertEqual(delegate.scrollToPosition, PhotoScrollPosition(handle: 1, date: try "2020-09-13T12:01:04Z".date))
    }
}

final class MockPhotoLibraryCollectionViewScroller: PhotoLibraryCollectionViewScrolling {
    var scrollToPosition: PhotoScrollPosition?
    var currentPosition: PhotoScrollPosition?
    
    func scrollTo(_ position: PhotoScrollPosition) {
        scrollToPosition = position
    }
    
    func position(at indexPath: IndexPath) -> PhotoScrollPosition? {
        currentPosition
    }
}
