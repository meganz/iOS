import MEGADomain
import Testing

@Suite("AutoPurgePeriodTests")
struct AutoPurgePeriodTests {
    
    @Suite("Duration in Days")
    struct DurationInDaysTests {
        @Test("None has no duration")
        func noneDuration() {
            #expect(AutoPurgePeriod.none.durationInDays == nil)
        }
        
        @Test("Never is 0 days")
        func neverDuration() {
            #expect(AutoPurgePeriod.never.durationInDays == 0)
        }
        
        @Test("Days case returns correct duration")
        func daysDuration() {
            #expect(AutoPurgePeriod.days(7).durationInDays == 7)
        }
        
        @Test("Years case returns correct duration")
        func yearsDuration() {
            #expect(AutoPurgePeriod.years(1).durationInDays == 365)
            #expect(AutoPurgePeriod.years(5).durationInDays == 1825)
        }
    }
    
    @Suite("ID")
    struct IDTests {
        @Test("None ID is -2")
        func noneID() {
            #expect(AutoPurgePeriod.none.id == -2)
        }
        
        @Test("Never ID is -1")
        func neverID() {
            #expect(AutoPurgePeriod.never.id == -1)
        }
        
        @Test("Days ID matches the number of days")
        func daysID() {
            #expect(AutoPurgePeriod.days(7).id == 7)
        }
        
        @Test("Years ID matches the number of days")
        func yearsID() {
            #expect(AutoPurgePeriod.years(1).id == 365)
        }
    }
    
    @Suite("Options for Account Types")
    @MainActor
    struct OptionsTests {
        @Test("Paid account returns all options")
        func paidAccountOptions() {
            let options = AutoPurgePeriod.options(forPaidAccount: true)
            #expect(options == [.sevenDays, .fourteenDays, .thirtyDays, .sixtyDays, .oneYear, .fiveYears, .tenYears, .never])
        }
        
        @Test("Free account returns limited options")
        func freeAccountOptions() {
            let options = AutoPurgePeriod.options(forPaidAccount: false)
            #expect(options == [.sevenDays, .fourteenDays, .thirtyDays])
        }
    }
    
    @Suite("Init from Days")
    @MainActor
    struct InitFromDaysTests {
        @Test("Valid days initialize correctly")
        func validDays() {
            #expect(AutoPurgePeriod(fromDays: 0) == .never)
            #expect(AutoPurgePeriod(fromDays: 7) == .sevenDays)
            #expect(AutoPurgePeriod(fromDays: 14) == .fourteenDays)
            #expect(AutoPurgePeriod(fromDays: 30) == .thirtyDays)
            #expect(AutoPurgePeriod(fromDays: 60) == .sixtyDays)
            #expect(AutoPurgePeriod(fromDays: 365) == .oneYear)
            #expect(AutoPurgePeriod(fromDays: 1825) == .fiveYears)
            #expect(AutoPurgePeriod(fromDays: 3650) == .tenYears)
        }
        
        @Test("Invalid days default to .none")
        func invalidDays() {
            #expect(AutoPurgePeriod(fromDays: 100) == .none)
        }
    }
    
    @Suite("Equatable Conformance")
    @MainActor
    struct EquatableTests {
        @Test("Cases are correctly compared for equality")
        func equality() {
            #expect(AutoPurgePeriod.none == .none)
            #expect(AutoPurgePeriod.days(30) == .thirtyDays)
        }
        
        @Test("Cases are correctly compared for inequality")
        func inequality() {
            #expect(AutoPurgePeriod.days(30) != .sixtyDays)
            #expect(AutoPurgePeriod.years(1) != .fiveYears)
        }
    }
}
