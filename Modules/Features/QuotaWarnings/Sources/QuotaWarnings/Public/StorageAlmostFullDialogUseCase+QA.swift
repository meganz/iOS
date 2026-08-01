// Not wrapped in `#if DEBUG` — see the note in QAQuotaDialogUseCase.swift (QA config builds packages
// as release). Unreachable in production: the only entry point is the QA settings screen, gated app-side.
import Foundation

/// What a trigger's daily allowance currently holds, so the QA simulator can show why the dialog will
/// or will not appear.
public struct QADailyAllowanceState: Sendable {
    /// Whether the dialog may be presented right now.
    public let isAvailable: Bool
    /// Presentations allowed per calendar day, or `nil` when the trigger is uncapped.
    public let dailyLimit: Int?
    /// The persisted count, as stored — **not** adjusted for the day having rolled over. Read it
    /// together with `lastShownDate`: a count at the limit still leaves the allowance available once
    /// that date is no longer today.
    public let shownCount: Int
    /// When the dialog was last presented for this trigger, or `nil` if it never has been.
    public let lastShownDate: Date?
}

// MARK: - QA affordances
public extension StorageAlmostFullDialogUseCase {
    /// **QA affordance only** — production code must go through `shouldShowDialog()`, which also
    /// confirms the account really is almost full.
    var _allowanceState: QADailyAllowanceState {
        guard let daily = _displayAllowance as? DailyDialogAllowance else {
            return QADailyAllowanceState(
                isAvailable: _displayAllowance.isAvailable,
                dailyLimit: nil,
                shownCount: 0,
                lastShownDate: nil
            )
        }
        return QADailyAllowanceState(
            isAvailable: daily.isAvailable,
            dailyLimit: daily.dailyLimit,
            shownCount: daily._storedShownCount,
            lastShownDate: daily._storedLastShownDate
        )
    }

    /// Backdates (or forward-dates) the stored last-shown date, so the calendar-day window can be
    /// crossed without waiting for midnight. Leaves the count alone — spend the allowance first, then
    /// move the date off today to watch it come back.
    ///
    /// **QA affordance only** — no-op for an uncapped trigger.
    func _setLastShownDate(_ date: Date) {
        (_displayAllowance as? DailyDialogAllowance)?._setLastShownDate(date)
    }

    /// Clears this trigger's stored count and date. **QA affordance only.**
    func _resetDailyCount() {
        (_displayAllowance as? DailyDialogAllowance)?._resetDailyCount()
    }

    /// Clears every storage almost-full trigger's daily count. **QA affordance only.**
    static func _resetAllDailyCounts() {
        DailyDialogAllowance.allStorageAlmostFull.forEach { $0._resetDailyCount() }
    }
}
