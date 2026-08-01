import Foundation
import MEGADomain
import MEGAPreference

/// Allows a fixed number of presentations per calendar day (00:00–23:59, device local calendar).
///
/// Two triggers share a budget only by being built on the same keys, so each trigger that needs its own allowance gets its own key pair.
///
/// The window is fixed rather than rolling: the stored count is treated as `0` as soon as the stored date is no longer today
struct DailyDialogAllowance: DialogDisplayAllowance {
    let shownCountKey: PreferenceKeyEntity
    let lastShownDateKey: PreferenceKeyEntity
    let dailyLimit: Int

    private let calendar: Calendar
    private let currentDate: @Sendable () -> Date

    @PreferenceWrapper<Int, PreferenceKeyEntity>
    private var shownCount: Int

    @PreferenceWrapper<Date?, PreferenceKeyEntity>
    private var lastShownDate: Date?

    init(
        shownCountKey: PreferenceKeyEntity,
        lastShownDateKey: PreferenceKeyEntity,
        dailyLimit: Int,
        preferenceUseCase: some PreferenceUseCaseProtocol = PreferenceUseCase.default,
        calendar: Calendar = .autoupdatingCurrent,
        currentDate: @escaping @Sendable () -> Date = { Date() }
    ) {
        self.shownCountKey = shownCountKey
        self.lastShownDateKey = lastShownDateKey
        self.dailyLimit = dailyLimit
        self.calendar = calendar
        self.currentDate = currentDate

        _shownCount = PreferenceWrapper(key: shownCountKey, defaultValue: 0, useCase: preferenceUseCase)
        _lastShownDate = PreferenceWrapper(key: lastShownDateKey, defaultValue: nil, useCase: preferenceUseCase)
    }

    var isAvailable: Bool {
        shownCountToday < dailyLimit
    }

    func consume() {
        shownCount = shownCountToday + 1
        lastShownDate = currentDate()
    }

    /// Clears this allowance's count. **QA affordance only** , production code must never call it,
    func _resetDailyCount() {
        $shownCount.remove()
        $lastShownDate.remove()
    }

    /// The persisted count, as stored — not adjusted for the day having rolled over.
    /// **QA affordance only.** (`_shownCount` is taken: it is the property wrapper's own storage.)
    var _storedShownCount: Int { shownCount }

    /// **QA affordance only.**
    var _storedLastShownDate: Date? { lastShownDate }

    /// Backdates (or forward-dates) the stored date so QA can cross the calendar-day boundary without
    /// waiting for midnight. Leaves the count alone — that pairing is the whole point: count at the
    /// limit + a date that is no longer today is what makes the allowance available again.
    ///
    /// **QA affordance only** — production code must never call it.
    func _setLastShownDate(_ date: Date) {
        lastShownDate = date
    }

    private var shownCountToday: Int {
        guard let lastShownDate,
              calendar.isDate(lastShownDate, inSameDayAs: currentDate()) else { return 0 }
        return shownCount
    }
}

// MARK: - Storage almost-full allowances
extension DailyDialogAllowance {
    /// Spent when the almost-full dialog is shown as the app opens (Every app login).
    static var storageAlmostFullOnAppOpen: DailyDialogAllowance {
        DailyDialogAllowance(
            shownCountKey: .storageAlmostFullOnAppOpenDialogShownCount,
            lastShownDateKey: .storageAlmostFullOnAppOpenDialogLastShownDate,
            dailyLimit: 1
        )
    }

    /// Spent when the almost-full dialog is shown after a successful upload.
    static var storageAlmostFullAfterUpload: DailyDialogAllowance {
        DailyDialogAllowance(
            shownCountKey: .storageAlmostFullAfterUploadDialogShownCount,
            lastShownDateKey: .storageAlmostFullAfterUploadDialogLastShownDate,
            dailyLimit: 1
        )
    }

    /// Every almost-full allowance, so a QA reset does not have to remember them one by one.
    static var allStorageAlmostFull: [DailyDialogAllowance] {
        [.storageAlmostFullOnAppOpen, .storageAlmostFullAfterUpload]
    }
}
