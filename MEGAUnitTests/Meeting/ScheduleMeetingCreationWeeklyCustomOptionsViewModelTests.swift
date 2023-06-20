import XCTest
@testable import MEGA
import MEGADomain
import MEGADomainMock

final class ScheduleMeetingCreationWeeklyCustomOptionsViewModelTests: XCTestCase {
    
    func testWeekDaySymbols_shouldMatch() {
        XCTAssertEqual(makeViewModel().weekdaySymbols, WeekDaysInformation().symbols)
    }
    
    func testSelectedWeekDays_givenOnlyOneWeekDay_shouldMatch() {
        let viewModel = makeViewModel(withWeekDayList: [1])
        XCTAssertEqual(viewModel.selectedWeekDays, Set([WeekDaysInformation().symbols[0]]))
    }
    
    func testUpdateWeekDayList_withSingleDaySelected_shouldMatch() {
        let viewModel = makeViewModel(withWeekDayList: [5])
        viewModel.updateWeekDayList(Set([WeekDaysInformation().symbols[0]]))
        XCTAssertEqual(viewModel.rules.weekDayList, [1])
    }
    
    func testUpdateWeekDayList_withAllDaysSelected_shouldMatch() {
        let viewModel = makeViewModel(withWeekDayList: [5])
        viewModel.updateWeekDayList(Set(WeekDaysInformation().symbols))
        XCTAssertEqual(viewModel.rules.weekDayList, Array(1...7))
    }
    
    func testToogleSelection_givenOnlyWeekDaySelectedShouldNotBeRemoved_shouldMatch() {
        let viewModel = makeViewModel(withWeekDayList: [1])
        viewModel.toggleSelection(forWeekDay: WeekDaysInformation().symbols[0])
        XCTAssertEqual(viewModel.rules.weekDayList, [1])
    }
    
    func testToogleSelection_weekDayListShouldAddTheWeekDay_shouldMatch() {
        let viewModel = makeViewModel(withWeekDayList: [1])
        viewModel.toggleSelection(forWeekDay: WeekDaysInformation().symbols[1])
        XCTAssertEqual(viewModel.rules.weekDayList, [1, 2])
    }
    
    func testToogleSelection_weekDayListShouldAddTheWeekDayAndAlsoSorted_shouldMatch() {
        let viewModel = makeViewModel(withWeekDayList: [4])
        viewModel.toggleSelection(forWeekDay: WeekDaysInformation().symbols[1])
        XCTAssertEqual(viewModel.rules.weekDayList, [2, 4])
    }
    
    func testUpdateInterval_changeIntervalToThree_shouldMatch() {
        let viewModel = makeViewModel(withWeekDayList: [4])
        viewModel.update(interval: 5)
        XCTAssertEqual(viewModel.rules.interval, 5)
    }
    
    // MARK: - Private methods
    
    private func makeViewModel(
        withWeekDayList weekDayList: [Int]? = nil
    ) -> ScheduleMeetingCreationWeeklyCustomOptionsViewModel {
        let rules = ScheduledMeetingRulesEntity(frequency: .weekly, weekDayList: weekDayList)
        return ScheduleMeetingCreationWeeklyCustomOptionsViewModel(rules: rules)
    }
}
