@testable import MEGA
import MEGADomain
import MEGADomainMock
import XCTest

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
        XCTAssertEqual(viewModel.selectedCustomOption, viewModel.monthlyCustomOptions[1])
    }
    
    func testSelectedCustomOption_withEachSelected_shouldMatch() {
        let viewModel = viewModel(forMonthDayList: [3])
        XCTAssertEqual(viewModel.selectedCustomOption, viewModel.monthlyCustomOptions[0])
    }
    
    func testSelectedDates_withSingleDate_shouldMatch() {
        let viewModel = viewModel(forMonthDayList: [3])
        XCTAssertEqual(viewModel.selectedDays, Set(["3"]))
    }
    
    func testSelectedDates_withMultipleDate_shouldMatch() {
        let viewModel = viewModel(forMonthDayList: [1, 5])
        XCTAssertEqual(viewModel.selectedDays, Set(["1", "5"]))
    }
    
    func testResetSelection_withMonthDayList_shouldMatch() throws {
        let sampleDate = try XCTUnwrap(sampleDate())
        let viewModel = viewModel(forMonthDayList: [3], startDate: sampleDate)
        viewModel.resetSelection(to: viewModel.monthlyCustomOptions[0])
        XCTAssertEqual(
            viewModel.rules.monthDayList,
            [16]
        )
    }
    
    func testResetSelection_withMonthWeekDayList_shouldMatch() throws {
        let startDate = try XCTUnwrap(sampleDate())
        let viewModel = viewModel(forMonthWeekDayList: [[1, 5]], startDate: startDate)
        viewModel.resetSelection(to: viewModel.monthlyCustomOptions[1])
        XCTAssertEqual(viewModel.rules.monthWeekDayList, [[3, 2]])
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
    
    func testUpdateInterval_changeIntervalToThree_shouldMatch() {
        let viewModel = viewModel(forMonthDayList: [31])
        viewModel.update(interval: 3)
        XCTAssertEqual(viewModel.rules.interval, 3)
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
        forMonthDayList monthDayList: [Int],
        startDate: Date = Date()
    ) -> ScheduleMeetingCreationMonthlyCustomOptionsViewModel {
        let rules = ScheduledMeetingRulesEntity(
            frequency: .monthly,
            monthDayList: monthDayList
        )
        return ScheduleMeetingCreationMonthlyCustomOptionsViewModel(rules: rules, startDate: startDate)
    }
    
    private func viewModel(
        forMonthWeekDayList monthWeekDayList: [[Int]],
        startDate: Date = Date()
    ) -> ScheduleMeetingCreationMonthlyCustomOptionsViewModel {
        let rules = ScheduledMeetingRulesEntity(
            frequency: .monthly,
            monthWeekDayList: monthWeekDayList
        )
        return ScheduleMeetingCreationMonthlyCustomOptionsViewModel(rules: rules, startDate: startDate)
    }
    
    private func viewModel(startDate: Date = Date()) -> ScheduleMeetingCreationMonthlyCustomOptionsViewModel {
        let rules = ScheduledMeetingRulesEntity(frequency: .invalid)
        return ScheduleMeetingCreationMonthlyCustomOptionsViewModel(rules: rules, startDate: startDate)
    }
    
    private func sampleDate() -> Date? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd/MM/yyyy"
        return dateFormatter.date(from: "16/05/2023")
    }
}
