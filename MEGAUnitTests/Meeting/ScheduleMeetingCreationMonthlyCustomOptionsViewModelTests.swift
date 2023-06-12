import XCTest
@testable import MEGA
import MEGADomain
import MEGADomainMock

final class ScheduleMeetingCreationMonthlyCustomOptionsViewModelTests: XCTestCase {
    
    func testWeekDaySymbols_shouldMatch() {
        XCTAssertEqual(viewModel().weekdaySymbols, WeekDaysInformation().symbols)
    }
    
    func testMonthlyCustomOptions_shouldMatch() {
        XCTAssertEqual(viewModel().monthlyCustomOptions.count, 2)
    }
    
    func testWeekNumbers_shouldMatch() {
        XCTAssertEqual(viewModel().weekNumbers.count, 5)
    }
    
    func testSelectedWeekNumber_withFirstWeek_shouldMatch() {
        assertSelectedWeekNumber(3)
    }
    
    func testSelectedWeekNumber_withFourthWeek_shouldMatch() {
        assertSelectedWeekNumber(4)
    }
    
    func testSelectedWeekSymbol_withFirstDayOfTheWeek_shouldMatch() {
        assertSelectedWeekDay(1)
    }
        
    func testSelectedWeekSymbol_withThirdDayOfTheWeek_shouldMatch() {
        assertSelectedWeekDay(3)
    }
    
    func testSelectedCustomOption_withOnEachSelected_shouldMatch() {
        let viewModel = viewModel(forMonthWeekDayList: [[1, 2]])
        XCTAssertEqual(viewModel.selectedCustomOption(), viewModel.monthlyCustomOptions[0])
    }
    
    func testSelectedCustomOption_withEachSelected_shouldMatch() {
        let viewModel = viewModel(forMonthDayList: [3])
        XCTAssertEqual(viewModel.selectedCustomOption(), viewModel.monthlyCustomOptions[1])
    }
    
    func testSelectedDates_withSingleDate_shouldMatch() {
        let viewModel = viewModel(forMonthDayList: [3])
        XCTAssertEqual(viewModel.selectedDates(), Set(["3"]))
    }
    
    func testSelectedDates_withMultipleDate_shouldMatch() {
        let viewModel = viewModel(forMonthDayList: [1, 5])
        XCTAssertEqual(viewModel.selectedDates(), Set(["1", "5"]))
    }
    
    func testResetSelection_withMonthDayList_shouldMatch() throws {
        let viewModel = viewModel(forMonthDayList: [3])
        viewModel.resetSelection(to: viewModel.monthlyCustomOptions[1])
        let today = try XCTUnwrap(Calendar.current.dateComponents([.day], from: Date()).day)
        XCTAssertEqual(
            viewModel.rules.monthDayList,
            [today]
        )
    }
    
    func testResetSelection_withMonthWeekDayList_shouldMatch() {
        let viewModel = viewModel(forMonthWeekDayList: [[1, 5]])
        viewModel.resetSelection(to: viewModel.monthlyCustomOptions[0])
        XCTAssertEqual(viewModel.rules.monthWeekDayList, [[1, 1]])
    }
    
    func testUpdateMonthWeekDayList_shouldMatch() {
        let viewModel = viewModel(forMonthWeekDayList: [[1, 5]])
        viewModel.updateMonthWeekDayList([[1, 2]])
        XCTAssertEqual(viewModel.rules.monthWeekDayList, [[1, 2]])
    }
    
    func testUpdateSelectedMonthDayList_shouldMatch() {
        let viewModel = viewModel(forMonthDayList: [3])
        viewModel.updateSelectedMonthDayList([31])
        XCTAssertEqual(viewModel.rules.monthDayList, [31])
    }
    
    func testSelectedWeekNumberAndWeekDay_forFirstAndMonday_shouldMatch() {
        let viewModel = viewModel(forMonthWeekDayList: [[1, 5]])
        viewModel.selected(weekNumber: viewModel.weekNumbers[0], andWeekDay: viewModel.weekdaySymbols[0])
        XCTAssertEqual(viewModel.rules.monthWeekDayList, [[1, 1]])
    }
    
    func testSelectedWeekNumberAndWeekDay_forThirdAndFriday_shouldMatch() {
        let viewModel = viewModel(forMonthWeekDayList: [[1, 5]])
        viewModel.selected(weekNumber: viewModel.weekNumbers[2], andWeekDay: viewModel.weekdaySymbols[4])
        XCTAssertEqual(viewModel.rules.monthWeekDayList, [[3, 5]])
    }
    
    func testCalendarFootNote_givenDayIsTwentyNine_shouldMatch() {
        let viewModel = viewModel(forMonthDayList: [29])
        XCTAssertEqual(
            viewModel.calendarFooterNote(),
            Strings.Localizable.Meetings.ScheduleMeeting.Create.MonthlyRecurrenceOption.DayTwentyNineSelected.footNote)
    }
    
    func testCalendarFootNote_givenDayIsThirty_shouldMatch() {
        let viewModel = viewModel(forMonthDayList: [30])
        XCTAssertEqual(
            viewModel.calendarFooterNote(),
            Strings.Localizable.Meetings.ScheduleMeeting.Create.MonthlyRecurrenceOption.DayThirtySelected.footNote)
    }
    
    func testCalendarFootNote_givenDayIsThirtyOne_shouldMatch() {
        let viewModel = viewModel(forMonthDayList: [31])
        XCTAssertEqual(
            viewModel.calendarFooterNote(),
            Strings.Localizable.Meetings.ScheduleMeeting.Create.MonthlyRecurrenceOption.DayThirtyFirstSelected.footNote)
    }
    
    // MARK: - Private methods
    
    private func assertSelectedWeekDay(_ weekDay: Int) {
        let viewModel = viewModel(forMonthWeekDayList: [[1, weekDay]])
        XCTAssertEqual(viewModel.selectedWeekSymbol, WeekDaysInformation().symbols[weekDay - 1])
    }
    
    private func assertSelectedWeekNumber(_ weekNumber: Int) {
        let viewModel = viewModel(forMonthWeekDayList: [[weekNumber, 2]])
        XCTAssertEqual(viewModel.selectedWeekNumber, viewModel.weekNumbers[weekNumber - 1])
    }
    
    private func viewModel(
        forMonthDayList monthDayList: [Int]
    ) -> ScheduleMeetingCreationMonthlyCustomOptionsViewModel {
        let rules = ScheduledMeetingRulesEntity(
            frequency: .monthly,
            monthDayList: monthDayList
        )
        return ScheduleMeetingCreationMonthlyCustomOptionsViewModel(rules: rules)
    }
    
    private func viewModel(
        forMonthWeekDayList monthWeekDayList: [[Int]]
    ) -> ScheduleMeetingCreationMonthlyCustomOptionsViewModel {
        let rules = ScheduledMeetingRulesEntity(
            frequency: .monthly,
            monthWeekDayList: monthWeekDayList
        )
        return ScheduleMeetingCreationMonthlyCustomOptionsViewModel(rules: rules)
    }
    
    private func viewModel() -> ScheduleMeetingCreationMonthlyCustomOptionsViewModel {
        let rules = ScheduledMeetingRulesEntity(frequency: .invalid)
        return ScheduleMeetingCreationMonthlyCustomOptionsViewModel(rules: rules)
    }
}
