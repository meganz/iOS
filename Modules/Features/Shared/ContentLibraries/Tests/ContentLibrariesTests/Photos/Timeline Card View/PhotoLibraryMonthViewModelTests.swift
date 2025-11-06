import Combine
@testable import ContentLibraries
import MEGADomain
import MEGADomainMock
import XCTest

final class PhotoLibraryMonthViewModelTests: XCTestCase {
    private var subscriptions = Set<AnyCancellable>()
    
    @MainActor
    private func makeSUT() throws -> PhotoLibraryMonthViewModel {
        let nodes =  [
            NodeEntity(name: "a.jpg", handle: 1, modificationTime: try "2022-08-18T22:01:04Z".date),
            NodeEntity(name: "b.jpg", handle: 2, modificationTime: try "2021-07-18T22:01:04Z".date),
            NodeEntity(name: "c.mov", handle: 3, modificationTime: try "2020-04-18T22:01:04Z".date),
            NodeEntity(name: "d.mp4", handle: 4, modificationTime: try "2020-04-17T22:01:04Z".date)
        ]
        let library = nodes.toPhotoLibrary(withSortType: .modificationDesc, in: .GMT)
        let libraryViewModel = PhotoLibraryContentViewModel(library: library)
        libraryViewModel.selectedMode = .month
        return PhotoLibraryMonthViewModel(libraryViewModel: libraryViewModel)
    }
    
    @MainActor
    func testInit_defaultValue() throws {
        let sut = try makeSUT()
        XCTAssertEqual(sut.photoCategoryList, sut.libraryViewModel.library.photosByMonthList)
        XCTAssertEqual(sut.photoCategoryList.count, 3)
        XCTAssertEqual(sut.photoCategoryList[0].categoryDate, try "2022-08-18T22:01:04Z".date.removeDay(timeZone: .GMT))
        XCTAssertNil(sut.libraryViewModel.cardScrollPosition)
        XCTAssertNil(sut.libraryViewModel.photoScrollPosition)
        XCTAssertEqual(sut.libraryViewModel.selectedMode, .month)
        XCTAssertNil(sut.position)
    }
    
    @MainActor
    func testDidTapCategory_tappingMonthCard_goToDayMode() throws {
        let sut = try makeSUT()
        let category = sut.photoCategoryList[2]
        XCTAssertEqual(category.categoryDate, try "2020-04-17T22:01:04Z".date.removeDay(timeZone: .GMT))
        XCTAssertEqual(category.contentList.count, 2)
        sut.didTapCategory(category)
        XCTAssertEqual(sut.libraryViewModel.cardScrollPosition, category.position)
        XCTAssertNil(sut.libraryViewModel.photoScrollPosition)
        XCTAssertEqual(sut.libraryViewModel.selectedMode, .day)
    }
    
    @MainActor
    func testChangingSelectedMode_switchingFromMonthToYearMode_goToYearMode() throws {
        let sut = try makeSUT()
        sut.libraryViewModel.selectedMode = .year
        XCTAssertNil(sut.libraryViewModel.cardScrollPosition)
        XCTAssertNil(sut.libraryViewModel.photoScrollPosition)
    }
    
    @MainActor
    func testChangingSelectedMode_switchingFromMonthToDayMode_goToDayMode() throws {
        let sut = try makeSUT()
        sut.libraryViewModel.selectedMode = .day
        XCTAssertNil(sut.libraryViewModel.cardScrollPosition)
        XCTAssertNil(sut.libraryViewModel.photoScrollPosition)
    }
    
    @MainActor
    func testChangingSelectedMode_switchingFromMonthToAllMode_goToAllMode() throws {
        let sut = try makeSUT()
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
