import XCTest
@testable import MEGA
import MEGADomain
import Combine

final class ScheduleMeetingCreationRecurrenceOptionsViewModelTests: XCTestCase {
    private var subscriptions = Set<AnyCancellable>()

    func testRecurrenceOptions_forSectionZero_shouldMatch() {
        let viewModel = ScheduleMeetingCreationRecurrenceOptionsViewModel(
            router: ScheduleMeetingCreationRecurrenceOptionsRouter(
                presenter: UINavigationController(),
                rules: ScheduledMeetingRulesEntity(frequency: .invalid)
            )
        )
        
        XCTAssert(viewModel.recurrenceOptions(forSection: 0) == [.never, .daily, .weekly, .monthly])
    }
    
    func testRecurrenceOptions_forSectionOne_shouldMatch() {
        let viewModel = ScheduleMeetingCreationRecurrenceOptionsViewModel(
            router: ScheduleMeetingCreationRecurrenceOptionsRouter(
                presenter: UINavigationController(),
                rules: ScheduledMeetingRulesEntity(frequency: .invalid)
            )
        )
        
        XCTAssert(viewModel.recurrenceOptions(forSection: 1) == [.custom])
    }
    
    func testRecurrenceOptions_forSectionInvalidEntry_shouldBeEmpty() {
        let viewModel = ScheduleMeetingCreationRecurrenceOptionsViewModel(
            router: ScheduleMeetingCreationRecurrenceOptionsRouter(
                presenter: UINavigationController(),
                rules: ScheduledMeetingRulesEntity(frequency: .invalid)
            )
        )
        
        XCTAssert(viewModel.recurrenceOptions(forSection: 2) == [])
    }
    
    func testRuleChangeNotificaton_fromNeverToDailyRecurrence_shouldMatch() {
        let inputRules = [ScheduledMeetingRulesEntity(frequency: .invalid),
                          ScheduledMeetingRulesEntity(frequency: .daily, weekDayList: Array(1...7))]
        var outputRules: [ScheduledMeetingRulesEntity] = []
        let router = ScheduleMeetingCreationRecurrenceOptionsRouter(
            presenter: UINavigationController(),
            rules: inputRules[0]
        )
        
        let expectation = expectation(description: "Selection updated from never to daily")
        let viewModel = router.start()

        router.$rules.sink { rules in
            outputRules.append(rules)
            if outputRules.count == 2 {
                expectation.fulfill()
            }
        }
        .store(in: &subscriptions)
        
        viewModel.selectedOption = .daily
        wait(for: [expectation], timeout: 3)
        
        XCTAssert(inputRules == outputRules)
    }
    
    func testRuleChangeNotificaton_fromNeverToWeeklyRecurrence_shouldMatch() {
        let inputRules = [ScheduledMeetingRulesEntity(frequency: .invalid),
                          ScheduledMeetingRulesEntity(frequency: .weekly, weekDayList: weekDayListContainingOnlyToday())]
        var outputRules: [ScheduledMeetingRulesEntity] = []
        let router = ScheduleMeetingCreationRecurrenceOptionsRouter(
            presenter: UINavigationController(),
            rules: inputRules[0]
        )
        
        let expectation = expectation(description: "Selection updated from never to weekly")
        let viewModel = router.start()

        router.$rules.sink { rules in
            outputRules.append(rules)
            if outputRules.count == 2 {
                expectation.fulfill()
            }
        }
        .store(in: &subscriptions)

        viewModel.selectedOption = .weekly
        wait(for: [expectation], timeout: 3)
        
        XCTAssert(inputRules == outputRules)
    }
    
    func testRuleChangeNotificaton_fromNeverToMonthlyRecurrence_shouldMatch() throws {
        let day = try XCTUnwrap(Calendar.current.dateComponents([.day], from: Date()).day)
        let inputRules = [ScheduledMeetingRulesEntity(frequency: .invalid),
                          ScheduledMeetingRulesEntity(frequency: .monthly, monthDayList: [day])]
        var outputRules: [ScheduledMeetingRulesEntity] = []
        let router = ScheduleMeetingCreationRecurrenceOptionsRouter(
            presenter: UINavigationController(),
            rules: inputRules[0]
        )
        
        let expectation = expectation(description: "Selection updated from never to monthly")
        let viewModel = router.start()

        router.$rules.sink { rules in
            outputRules.append(rules)
            if outputRules.count == 2 {
                expectation.fulfill()
            }
        }
        .store(in: &subscriptions)

        viewModel.selectedOption = .monthly
        wait(for: [expectation], timeout: 3)
        
        XCTAssert(inputRules == outputRules)
    }
    
    func testRuleChangeNotificaton_fromDialyToNeverRecurrence_shouldMatch() {
        let inputRules = [ScheduledMeetingRulesEntity(frequency: .daily, weekDayList: Array(1...7)),
                          ScheduledMeetingRulesEntity(frequency: .invalid)]
        var outputRules: [ScheduledMeetingRulesEntity] = []
        let router = ScheduleMeetingCreationRecurrenceOptionsRouter(
            presenter: UINavigationController(),
            rules: inputRules[0]
        )
        
        let expectation = expectation(description: "Selection updated to daily to never")
        let viewModel = router.start()

        router.$rules.sink { rules in
            outputRules.append(rules)
            if outputRules.count == 2 {
                expectation.fulfill()
            }
        }
        .store(in: &subscriptions)
        
        viewModel.selectedOption = .never
        wait(for: [expectation], timeout: 3)
        
        XCTAssert(inputRules == outputRules)
    }
    
    func testRuleChangeNotificaton_fromDailyToWeeklyRecurrence_shouldMatch() {
        let inputRules = [ScheduledMeetingRulesEntity(frequency: .daily, weekDayList: Array(1...7)),
                          ScheduledMeetingRulesEntity(frequency: .weekly, weekDayList: weekDayListContainingOnlyToday())]
        var outputRules: [ScheduledMeetingRulesEntity] = []
        let router = ScheduleMeetingCreationRecurrenceOptionsRouter(
            presenter: UINavigationController(),
            rules: inputRules[0]
        )
        
        let expectation = expectation(description: "Selection updated from daily to weekly")
        let viewModel = router.start()

        router.$rules.sink { rules in
            outputRules.append(rules)
            if outputRules.count == 2 {
                expectation.fulfill()
            }
        }
        .store(in: &subscriptions)

        viewModel.selectedOption = .weekly
        wait(for: [expectation], timeout: 3)
        
        XCTAssert(inputRules == outputRules)
    }
    
    func testRuleChangeNotificaton_fromDailyToMonthlyRecurrence_shouldMatch() throws {
        let day = try XCTUnwrap(Calendar.current.dateComponents([.day], from: Date()).day)
        let inputRules = [ScheduledMeetingRulesEntity(frequency: .daily, weekDayList: Array(1...7)),
                          ScheduledMeetingRulesEntity(frequency: .monthly, monthDayList: [day])]
        var outputRules: [ScheduledMeetingRulesEntity] = []
        let router = ScheduleMeetingCreationRecurrenceOptionsRouter(
            presenter: UINavigationController(),
            rules: inputRules[0]
        )
        
        let expectation = expectation(description: "Selection updated from daily to monthly")
        let viewModel = router.start()

        router.$rules.sink { rules in
            outputRules.append(rules)
            if outputRules.count == 2 {
                expectation.fulfill()
            }
        }
        .store(in: &subscriptions)

        viewModel.selectedOption = .monthly
        wait(for: [expectation], timeout: 3)
        
        XCTAssert(inputRules == outputRules)
    }
    
    func testRuleChangeNotificaton_fromWeeklyToNeverRecurrence_shouldMatch() {
        let inputRules = [ScheduledMeetingRulesEntity(frequency: .weekly, weekDayList: weekDayListContainingOnlyToday()),
                          ScheduledMeetingRulesEntity(frequency: .invalid)]
        var outputRules: [ScheduledMeetingRulesEntity] = []
        let router = ScheduleMeetingCreationRecurrenceOptionsRouter(
            presenter: UINavigationController(),
            rules: inputRules[0]
        )
        
        let expectation = expectation(description: "Selection updated from weekly to never")
        let viewModel = router.start()

        router.$rules.sink { rules in
            outputRules.append(rules)
            if outputRules.count == 2 {
                expectation.fulfill()
            }
        }
        .store(in: &subscriptions)
        
        viewModel.selectedOption = .never
        wait(for: [expectation], timeout: 3)
        
        XCTAssert(inputRules == outputRules)
    }
    
    func testRuleChangeNotificaton_fromWeeklyToDailyRecurrence_shouldMatch() {
        let inputRules = [ScheduledMeetingRulesEntity(frequency: .weekly, weekDayList: weekDayListContainingOnlyToday()),
                          ScheduledMeetingRulesEntity(frequency: .daily, weekDayList: Array(1...7))]
        var outputRules: [ScheduledMeetingRulesEntity] = []
        let router = ScheduleMeetingCreationRecurrenceOptionsRouter(
            presenter: UINavigationController(),
            rules: inputRules[0]
        )
        
        let expectation = expectation(description: "Selection updated from weekly to daily")
        let viewModel = router.start()

        router.$rules.sink { rules in
            outputRules.append(rules)
            if outputRules.count == 2 {
                expectation.fulfill()
            }
        }
        .store(in: &subscriptions)

        viewModel.selectedOption = .daily
        wait(for: [expectation], timeout: 3)
        
        XCTAssert(inputRules == outputRules)
    }
    
    func testRuleChangeNotificaton_fromWeeklyToMonthlyRecurrence_shouldMatch() throws {
        let day = try XCTUnwrap(Calendar.current.dateComponents([.day], from: Date()).day)
        let inputRules = [ScheduledMeetingRulesEntity(frequency: .weekly, weekDayList: weekDayListContainingOnlyToday()),
                          ScheduledMeetingRulesEntity(frequency: .monthly, monthDayList: [day])]
        var outputRules: [ScheduledMeetingRulesEntity] = []
        let router = ScheduleMeetingCreationRecurrenceOptionsRouter(
            presenter: UINavigationController(),
            rules: inputRules[0]
        )
        
        let expectation = expectation(description: "Selection updated from weekly to monthly")
        let viewModel = router.start()

        router.$rules.sink { rules in
            outputRules.append(rules)
            if outputRules.count == 2 {
                expectation.fulfill()
            }
        }
        .store(in: &subscriptions)

        viewModel.selectedOption = .monthly
        wait(for: [expectation], timeout: 3)
        
        XCTAssert(inputRules == outputRules)
    }
    
    func testRuleChangeNotificaton_fromMonthlyToNeverRecurrence_shouldMatch() throws {
        let day = try XCTUnwrap(Calendar.current.dateComponents([.day], from: Date()).day)
        let inputRules = [ScheduledMeetingRulesEntity(frequency: .monthly, weekDayList: [day]),
                          ScheduledMeetingRulesEntity(frequency: .invalid)]
        var outputRules: [ScheduledMeetingRulesEntity] = []
        let router = ScheduleMeetingCreationRecurrenceOptionsRouter(
            presenter: UINavigationController(),
            rules: inputRules[0]
        )
        
        let expectation = expectation(description: "Selection updated from monthly to never")
        let viewModel = router.start()

        router.$rules.sink { rules in
            outputRules.append(rules)
            if outputRules.count == 2 {
                expectation.fulfill()
            }
        }
        .store(in: &subscriptions)

        viewModel.selectedOption = .never
        wait(for: [expectation], timeout: 3)
        
        XCTAssert(inputRules == outputRules)
    }
    
    func testRuleChangeNotificaton_fromMonthlyToDailyRecurrence_shouldMatch() throws {
        let day = try XCTUnwrap(Calendar.current.dateComponents([.day], from: Date()).day)
        let inputRules = [ScheduledMeetingRulesEntity(frequency: .monthly, weekDayList: [day]),
                          ScheduledMeetingRulesEntity(frequency: .daily, weekDayList: Array(1...7))]
        var outputRules: [ScheduledMeetingRulesEntity] = []
        let router = ScheduleMeetingCreationRecurrenceOptionsRouter(
            presenter: UINavigationController(),
            rules: inputRules[0]
        )
        
        let expectation = expectation(description: "Selection updated from monthly to daily")
        let viewModel = router.start()

        router.$rules.sink { rules in
            outputRules.append(rules)
            if outputRules.count == 2 {
                expectation.fulfill()
            }
        }
        .store(in: &subscriptions)
        
        viewModel.selectedOption = .daily
        wait(for: [expectation], timeout: 3)
        
        XCTAssert(inputRules == outputRules)
    }
    
    func testRuleChangeNotificaton_fromMonthlyToWeeklyRecurrence_shouldMatch() throws {
        let day = try XCTUnwrap(Calendar.current.dateComponents([.day], from: Date()).day)
        let inputRules = [ScheduledMeetingRulesEntity(frequency: .monthly, monthDayList: [day]),
                          ScheduledMeetingRulesEntity(frequency: .weekly, weekDayList: weekDayListContainingOnlyToday())]
        var outputRules: [ScheduledMeetingRulesEntity] = []
        let router = ScheduleMeetingCreationRecurrenceOptionsRouter(
            presenter: UINavigationController(),
            rules: inputRules[0]
        )
        
        let expectation = expectation(description: "Selection updated from monthly to weekly")
        let viewModel = router.start()

        router.$rules.sink { rules in
            outputRules.append(rules)
            if outputRules.count == 2 {
                expectation.fulfill()
            }
        }
        .store(in: &subscriptions)
        
        viewModel.selectedOption = .weekly
        wait(for: [expectation], timeout: 3)
        
        XCTAssert(inputRules == outputRules)
    }
    
    private func weekDayListContainingOnlyToday() -> [Int] {
        let weekDay = Calendar(identifier: .gregorian).component(.weekday, from: Date())
        return [((weekDay + 5) % 7) + 1] // gregorian - 1 is Sunday but we need Monday as 1
    }

}
