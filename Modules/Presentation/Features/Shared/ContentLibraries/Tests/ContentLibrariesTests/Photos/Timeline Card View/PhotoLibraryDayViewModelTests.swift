import Combine
@testable import ContentLibraries
import MEGADomain
import MEGADomainMock
import XCTest

final class PhotoLibraryDayViewModelTests: XCTestCase {
    private var sut: PhotoLibraryDayViewModel!
    private var subscriptions = Set<AnyCancellable>()
    
    @MainActor
    override func setUpWithError() throws {
        let nodes =  [
            NodeEntity(name: "a.jpg", handle: 1, modificationTime: try "2022-08-18T22:01:04Z".date),
            NodeEntity(name: "b.jpg", handle: 2, modificationTime: try "2020-04-18T20:01:04Z".date),
            NodeEntity(name: "c.mov", handle: 3, modificationTime: try "2020-04-18T12:01:04Z".date),
            NodeEntity(name: "d.mp4", handle: 4, modificationTime: try "2020-04-18T01:01:04Z".date)
        ]
        let library = nodes.toPhotoLibrary(withSortType: .modificationDesc, in: .GMT)
        let libraryViewModel = PhotoLibraryContentViewModel(library: library)
        libraryViewModel.selectedMode = .day
        sut = PhotoLibraryDayViewModel(libraryViewModel: libraryViewModel)
    }
    
    @MainActor
    func testInit_defaultValue() throws {
        XCTAssertEqual(sut.photoCategoryList, sut.libraryViewModel.library.photosByDayList)
        XCTAssertEqual(sut.photoCategoryList.count, 2)
        XCTAssertEqual(sut.photoCategoryList[0].categoryDate, try "2022-08-18T22:01:04Z".date.removeTimestamp(timeZone: .GMT))
        XCTAssertNil(sut.libraryViewModel.cardScrollPosition)
        XCTAssertNil(sut.libraryViewModel.photoScrollPosition)
        XCTAssertEqual(sut.libraryViewModel.selectedMode, .day)
        XCTAssertNil(sut.position)
    }
    
    @MainActor
    func testDidTapCategory_tappingDayCard_goToAllMode() throws {
        let category = sut.photoCategoryList[1]
        XCTAssertEqual(category.categoryDate, try "2020-04-18T01:01:04Z".date.removeTimestamp(timeZone: .GMT))
        XCTAssertEqual(category.contentList.count, 3)
        sut.didTapCategory(category)
        XCTAssertEqual(sut.libraryViewModel.cardScrollPosition, category.position)
        XCTAssertNil(sut.libraryViewModel.photoScrollPosition)
        XCTAssertEqual(sut.libraryViewModel.selectedMode, .all)
    }
    
    @MainActor
    func testChangingSelectedMode_switchingFromDayToYearMode_goToYearMode() throws {
        sut.libraryViewModel.selectedMode = .year
        XCTAssertNil(sut.libraryViewModel.cardScrollPosition)
        XCTAssertNil(sut.libraryViewModel.photoScrollPosition)
    }
    
    @MainActor
    func testChangingSelectedMode_switchingFromDayToMonthMode_goToMonthMode() throws {
        sut.libraryViewModel.selectedMode = .month
        XCTAssertNil(sut.libraryViewModel.cardScrollPosition)
        XCTAssertNil(sut.libraryViewModel.photoScrollPosition)
    }
    
    @MainActor
    func testChangingSelectedMode_switchingFromDayToAllMode_goToAllMode() throws {
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
