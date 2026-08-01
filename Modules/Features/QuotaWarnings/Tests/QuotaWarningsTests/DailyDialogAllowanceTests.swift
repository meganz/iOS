import Foundation
import MEGADomain
import MEGAPreferenceMocks
@testable import QuotaWarnings
import Testing

@Suite("DailyDialogAllowanceTests")
struct DailyDialogAllowanceTests {
    /// A fixed calendar so the tests do not depend on the machine's timezone.
    private static var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar
    }

    private static func date(_ day: Int, _ hour: Int, _ minute: Int) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: 7, day: day, hour: hour, minute: minute))!
    }

    /// Arbitrary keys — the mechanics are key-agnostic. The production wiring is pinned separately.
    private static func makeSUT(
        shownCountKey: PreferenceKeyEntity = .storageAlmostFullOnAppOpenDialogShownCount,
        lastShownDateKey: PreferenceKeyEntity = .storageAlmostFullOnAppOpenDialogLastShownDate,
        dailyLimit: Int = 1,
        preferenceUseCase: MockPreferenceUseCase = MockPreferenceUseCase(),
        now: Date
    ) -> DailyDialogAllowance {
        DailyDialogAllowance(
            shownCountKey: shownCountKey,
            lastShownDateKey: lastShownDateKey,
            dailyLimit: dailyLimit,
            preferenceUseCase: preferenceUseCase,
            calendar: calendar,
            currentDate: { now }
        )
    }

    /// A second allowance on a different key pair, to prove budgets do not leak into each other.
    private static func makeOtherSUT(
        preferenceUseCase: MockPreferenceUseCase,
        now: Date
    ) -> DailyDialogAllowance {
        makeSUT(
            shownCountKey: .storageAlmostFullAfterUploadDialogShownCount,
            lastShownDateKey: .storageAlmostFullAfterUploadDialogLastShownDate,
            preferenceUseCase: preferenceUseCase,
            now: now
        )
    }

    private static func storedCount(
        in preferenceUseCase: MockPreferenceUseCase,
        for allowance: DailyDialogAllowance
    ) -> Int? {
        preferenceUseCase.dict[allowance.shownCountKey.rawValue] as? Int
    }

    private static func storedDate(
        in preferenceUseCase: MockPreferenceUseCase,
        for allowance: DailyDialogAllowance
    ) -> Date? {
        preferenceUseCase.dict[allowance.lastShownDateKey.rawValue] as? Date
    }

    @Suite("Daily limit")
    struct DailyLimitTests {
        @Test("Is available on a fresh install")
        func freshInstall() {
            let sut = makeSUT(now: date(30, 10, 0))

            #expect(sut.isAvailable)
        }

        @Test("Is spent once its whole limit is consumed", arguments: [1, 2, 3])
        func afterConsumingTheLimit(dailyLimit: Int) {
            let preferenceUseCase = MockPreferenceUseCase()
            let sut = makeSUT(dailyLimit: dailyLimit, preferenceUseCase: preferenceUseCase, now: date(30, 10, 0))

            for _ in 0..<dailyLimit {
                #expect(sut.isAvailable, "should still be available before the limit is reached")
                sut.consume()
            }

            #expect(sut.isAvailable == false)
            #expect(storedCount(in: preferenceUseCase, for: sut) == dailyLimit)
        }

        @Test("Records both the count and the date")
        func recordsCountAndDate() {
            let preferenceUseCase = MockPreferenceUseCase()
            let now = date(30, 10, 0)
            let sut = makeSUT(preferenceUseCase: preferenceUseCase, now: now)

            sut.consume()

            #expect(storedCount(in: preferenceUseCase, for: sut) == 1)
            #expect(storedDate(in: preferenceUseCase, for: sut) == now)
        }
    }

    @Suite("Separate key pairs")
    struct KeyIsolationTests {
        @Test("Spending one allowance leaves the other's budget intact")
        func allowancesDoNotShareABudget() {
            let preferenceUseCase = MockPreferenceUseCase()
            let now = date(30, 10, 0)
            let sut = makeSUT(preferenceUseCase: preferenceUseCase, now: now)
            let other = makeOtherSUT(preferenceUseCase: preferenceUseCase, now: now)

            sut.consume()

            #expect(sut.isAvailable == false)
            #expect(other.isAvailable)
        }

        @Test("Each allowance writes only its own keys")
        func allowancesRecordSeparately() {
            let preferenceUseCase = MockPreferenceUseCase()
            let now = date(30, 10, 0)
            let sut = makeSUT(preferenceUseCase: preferenceUseCase, now: now)
            let other = makeOtherSUT(preferenceUseCase: preferenceUseCase, now: now)

            other.consume()

            #expect(storedCount(in: preferenceUseCase, for: other) == 1)
            #expect(storedCount(in: preferenceUseCase, for: sut) == nil)
        }
    }

    @Suite("Fixed 00:00-23:59 window")
    struct FixedWindowTests {
        @Test("Budget resets just after midnight, not 24 hours after the last consume")
        func resetsAtMidnight() {
            let preferenceUseCase = MockPreferenceUseCase()
            let yesterday = makeSUT(preferenceUseCase: preferenceUseCase, now: date(29, 23, 50))
            yesterday.consume()
            #expect(yesterday.isAvailable == false)

            let today = makeSUT(preferenceUseCase: preferenceUseCase, now: date(30, 0, 5))

            #expect(today.isAvailable)
        }

        @Test("Budget is not restored later on the same day")
        func staysSpentUntilEndOfDay() {
            let preferenceUseCase = MockPreferenceUseCase()
            let earlier = makeSUT(preferenceUseCase: preferenceUseCase, now: date(30, 0, 1))
            earlier.consume()

            let later = makeSUT(preferenceUseCase: preferenceUseCase, now: date(30, 23, 59))

            #expect(later.isAvailable == false)
        }

        @Test("Count restarts at one on a new day instead of accumulating")
        func countRestartsOnNewDay() {
            let preferenceUseCase = MockPreferenceUseCase()
            let yesterday = makeSUT(preferenceUseCase: preferenceUseCase, now: date(29, 12, 0))
            yesterday.consume()

            let today = makeSUT(preferenceUseCase: preferenceUseCase, now: date(30, 12, 0))
            today.consume()

            #expect(storedCount(in: preferenceUseCase, for: today) == 1)
        }
    }

    @Suite("QA reset")
    struct ResetTests {
        @Test("Resetting the daily count restores the budget")
        func resetRestoresBudget() {
            let preferenceUseCase = MockPreferenceUseCase()
            let sut = makeSUT(preferenceUseCase: preferenceUseCase, now: date(30, 10, 0))
            sut.consume()

            sut._resetDailyCount()

            #expect(sut.isAvailable)
        }

        @Test("Resetting removes both stored keys rather than writing empty values")
        func resetRemovesStoredKeys() {
            let preferenceUseCase = MockPreferenceUseCase()
            let sut = makeSUT(preferenceUseCase: preferenceUseCase, now: date(30, 10, 0))
            sut.consume()

            sut._resetDailyCount()

            let keys = preferenceUseCase.dict.keys
            #expect(keys.contains(sut.shownCountKey.rawValue) == false)
            #expect(keys.contains(sut.lastShownDateKey.rawValue) == false)
        }

        @Test("Resetting one allowance leaves the other untouched")
        func resetIsPerAllowance() {
            let preferenceUseCase = MockPreferenceUseCase()
            let now = date(30, 10, 0)
            let sut = makeSUT(preferenceUseCase: preferenceUseCase, now: now)
            let other = makeOtherSUT(preferenceUseCase: preferenceUseCase, now: now)
            sut.consume()
            other.consume()

            sut._resetDailyCount()

            #expect(sut.isAvailable)
            #expect(other.isAvailable == false)
        }

        @Test("Moving the stored date off today makes a spent allowance available again")
        func backdatingRestoresBudget() {
            let preferenceUseCase = MockPreferenceUseCase()
            let sut = makeSUT(preferenceUseCase: preferenceUseCase, now: date(30, 10, 0))
            sut.consume()
            #expect(sut.isAvailable == false)

            sut._setLastShownDate(date(29, 10, 0))

            #expect(sut.isAvailable)
            #expect(sut._storedShownCount == 1, "the count is left alone — only the day changed")
        }

        @Test("Moving the stored date back onto today spends it again")
        func redatingToTodaySpendsBudget() {
            let preferenceUseCase = MockPreferenceUseCase()
            let sut = makeSUT(preferenceUseCase: preferenceUseCase, now: date(30, 10, 0))
            sut.consume()
            sut._setLastShownDate(date(29, 10, 0))

            sut._setLastShownDate(date(30, 8, 0))

            #expect(sut.isAvailable == false)
        }

        @Test("Reports the stored count and date")
        func reportsStoredState() {
            let preferenceUseCase = MockPreferenceUseCase()
            let now = date(30, 10, 0)
            let sut = makeSUT(preferenceUseCase: preferenceUseCase, now: now)
            #expect(sut._storedShownCount == 0)
            #expect(sut._storedLastShownDate == nil)

            sut.consume()

            #expect(sut._storedShownCount == 1)
            #expect(sut._storedLastShownDate == now)
        }

        @Test("Counting restarts from one after a reset")
        func countRestartsAfterReset() {
            let preferenceUseCase = MockPreferenceUseCase()
            let sut = makeSUT(preferenceUseCase: preferenceUseCase, now: date(30, 10, 0))
            sut.consume()
            sut._resetDailyCount()

            sut.consume()

            #expect(storedCount(in: preferenceUseCase, for: sut) == 1)
        }
    }

    /// Pins the product wiring: which keys each trigger draws on, and how much it allows.
    /// Reads properties only — no preference access, so the real `UserDefaults` stays untouched.
    @Suite("Storage almost-full allowances")
    struct StorageAlmostFullAllowanceTests {
        @Test("On app open draws on its own keys and allows one a day")
        func onAppOpen() {
            let sut = DailyDialogAllowance.storageAlmostFullOnAppOpen

            #expect(sut.shownCountKey == .storageAlmostFullOnAppOpenDialogShownCount)
            #expect(sut.lastShownDateKey == .storageAlmostFullOnAppOpenDialogLastShownDate)
            #expect(sut.dailyLimit == 1)
        }

        @Test("After a successful upload draws on its own keys and allows one a day")
        func afterUpload() {
            let sut = DailyDialogAllowance.storageAlmostFullAfterUpload

            #expect(sut.shownCountKey == .storageAlmostFullAfterUploadDialogShownCount)
            #expect(sut.lastShownDateKey == .storageAlmostFullAfterUploadDialogLastShownDate)
            #expect(sut.dailyLimit == 1)
        }

        @Test("Every almost-full allowance is listed for the QA reset")
        func allAreListed() {
            let listedKeys = DailyDialogAllowance.allStorageAlmostFull.map(\.shownCountKey)

            #expect(listedKeys == [
                .storageAlmostFullOnAppOpenDialogShownCount,
                .storageAlmostFullAfterUploadDialogShownCount
            ])
        }
    }
}
