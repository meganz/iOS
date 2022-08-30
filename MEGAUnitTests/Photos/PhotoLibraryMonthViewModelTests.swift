import XCTest
@testable import MEGA
import MEGADomain
import MEGADomainMock
import Combine

final class PhotoLibraryMonthViewModelTests: XCTestCase {
    private var sut: PhotoLibraryMonthViewModel!
    private var subscriptions = Set<AnyCancellable>()
    
    override func setUpWithError() throws {
        let nodes =  [
            NodeEntity(name: "a.jpg", handle: 1, modificationTime: try "2022-08-18T22:01:04Z".date),
            NodeEntity(name: "b.jpg", handle: 2, modificationTime: try "2021-07-18T22:01:04Z".date),
            NodeEntity(name: "c.mov", handle: 3, modificationTime: try "2020-04-18T22:01:04Z".date),
            NodeEntity(name: "d.mp4", handle: 4, modificationTime: try "2020-04-17T22:01:04Z".date),
        ]
        let library = nodes.toPhotoLibrary(withSortType: .newest, in: TimeZone(secondsFromGMT: 0))
        let libraryViewModel = PhotoLibraryContentViewModel(library: library)
        libraryViewModel.selectedMode = .month
        sut = PhotoLibraryMonthViewModel(libraryViewModel: libraryViewModel)
        
        XCTAssertEqual(sut.photoCategoryList, library.photosByMonthList)
        XCTAssertEqual(sut.photoCategoryList.count, 3)
        XCTAssertEqual(sut.photoCategoryList[0].categoryDate, try "2022-08-18T22:01:04Z".date.removeDay(timeZone: TimeZone(secondsFromGMT: 0)))
        XCTAssertNil(libraryViewModel.cardScrollPosition)
        XCTAssertNil(libraryViewModel.photoScrollPosition)
        XCTAssertEqual(libraryViewModel.selectedMode, .month)
    }
    
    func testDidTapCategory_tappingMonthCard_goToDayMode() throws {
        let category = sut.photoCategoryList[2]
        XCTAssertEqual(category.categoryDate, try "2020-04-17T22:01:04Z".date.removeDay(timeZone: TimeZone(secondsFromGMT: 0)))
        XCTAssertEqual(category.contentList.count, 2)
        sut.didTapCategory(category)
        XCTAssertEqual(sut.libraryViewModel.cardScrollPosition, category.position)
        XCTAssertNil(sut.libraryViewModel.photoScrollPosition)
        XCTAssertEqual(sut.libraryViewModel.selectedMode, .day)
    }
    
    func testChangingSelectedMode_switchingFromMonthToYearMode_goToYearMode() throws {
        sut.libraryViewModel.selectedMode = .year
        XCTAssertNil(sut.libraryViewModel.cardScrollPosition)
        XCTAssertNil(sut.libraryViewModel.photoScrollPosition)
    }
    
    func testChangingSelectedMode_switchingFromMonthToDayMode_goToDayMode() throws {
        sut.libraryViewModel.selectedMode = .day
        XCTAssertNil(sut.libraryViewModel.cardScrollPosition)
        XCTAssertNil(sut.libraryViewModel.photoScrollPosition)
    }
    
    func testChangingSelectedMode_switchingFromMonthToAllMode_goToAllMode() throws {
        var didFinishPhotoCardScrollPositionCalculationNotificationCount = 0
        
        NotificationCenter
            .default
            .publisher(for: .didFinishPhotoCardScrollPositionCalculation)
            .sink { _ in
                didFinishPhotoCardScrollPositionCalculationNotificationCount += 1
            }
            .store(in: &subscriptions)
        
        
        sut.libraryViewModel.selectedMode = .all
        XCTAssertNil(sut.libraryViewModel.cardScrollPosition)
        XCTAssertNil(sut.libraryViewModel.photoScrollPosition)
        XCTAssertEqual(didFinishPhotoCardScrollPositionCalculationNotificationCount, 1)
    }
}
