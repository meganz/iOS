import XCTest
@testable import MEGA
import UIKit

final class PhotoLibraryCollectionViewScrollTrackerTests: XCTestCase {
    private let delegate = MockPhotoLibraryCollectionViewScroller()
    private let libraryViewModel = PhotoLibraryContentViewModel(library: PhotoLibrary())
    private lazy var tracker = PhotoLibraryCollectionViewScrollTracker(
        libraryViewModel: libraryViewModel,
        collectionView: UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout()),
        delegate: delegate,
        in: .GMT
    )

    override func setUpWithError() throws {
        tracker.startTrackingScrolls()
    }

    func testScroll_noCardPositionAndNoPhotoPosition_scrollToTop() throws {
        libraryViewModel.cardScrollPosition = nil
        libraryViewModel.photoScrollPosition = nil
        
        NotificationCenter.default.post(name: .didFinishPhotoCardScrollPositionCalculation, object: nil)
        XCTAssertEqual(delegate.scrollToPosition, .top)
    }
    
    func testScroll_hasCardPositionAndNoPhotoPosition_scrollToCardPosition() throws {
        let position = PhotoScrollPosition(handle: 1, date: Date())
        libraryViewModel.cardScrollPosition = position
        libraryViewModel.photoScrollPosition = nil
        
        NotificationCenter.default.post(name: .didFinishPhotoCardScrollPositionCalculation, object: nil)
        XCTAssertEqual(delegate.scrollToPosition, position)
    }
    
    func testScroll_noCardPositionAndhasPhotoPosition_scrollToPhotoPosition() throws {
        let position = PhotoScrollPosition(handle: 1, date: Date())
        libraryViewModel.cardScrollPosition = nil
        libraryViewModel.photoScrollPosition = position
        
        NotificationCenter.default.post(name: .didFinishPhotoCardScrollPositionCalculation, object: nil)
        XCTAssertEqual(delegate.scrollToPosition, position)
    }
    
    func testScroll_hasCardPositionAndhasPhotoPositionAndSameDay_noScroll() throws {
        libraryViewModel.cardScrollPosition = PhotoScrollPosition(handle: 1, date: try "2020-04-18T12:01:04Z".date)
        libraryViewModel.photoScrollPosition = PhotoScrollPosition(handle: 10, date: try "2020-04-18T09:41:54Z".date)
        
        NotificationCenter.default.post(name: .didFinishPhotoCardScrollPositionCalculation, object: nil)
        XCTAssertNil(delegate.scrollToPosition)
    }
    
    func testScroll_hasCardPositionAndhasPhotoPositionAndDifferentDay_scrollToCardPosition() throws {
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
