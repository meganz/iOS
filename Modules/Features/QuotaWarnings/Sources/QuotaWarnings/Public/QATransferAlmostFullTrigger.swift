// Not wrapped in `#if DEBUG` — see the note in QAQuotaDialogUseCase.swift (QA config builds packages
// as release). Unreachable in production: the only entry point is the QA settings screen, gated app-side.
import Foundation

/// The transfer almost-full triggers that draw on a daily allowance. **QA affordance only** — the
/// production path reaches these allowances through `TransferQuotaWarningMonitor`.
public enum QATransferAlmostFullTrigger: CaseIterable, Sendable {
    case limitedDownload
    case limitedStreaming

    public var title: String {
        switch self {
        case .limitedDownload: "Transfer – limited download"
        case .limitedStreaming: "Transfer – limited streaming"
        }
    }

    /// What this trigger's daily allowance currently holds.
    public var _allowanceState: QADailyAllowanceState {
        let allowance = allowance
        return QADailyAllowanceState(
            isAvailable: allowance.isAvailable,
            dailyLimit: allowance.dailyLimit,
            shownCount: allowance._storedShownCount,
            lastShownDate: allowance._storedLastShownDate
        )
    }

    /// Backdates (or forward-dates) the stored last-shown date, so the calendar-day window can be
    /// crossed without waiting for midnight. Leaves the count alone.
    public func _setLastShownDate(_ date: Date) {
        allowance._setLastShownDate(date)
    }

    /// Clears this trigger's stored count and date.
    public func _resetDailyCount() {
        allowance._resetDailyCount()
    }

    /// Clears every transfer almost-full trigger's daily count.
    public static func _resetAllDailyCounts() {
        allCases.forEach { $0._resetDailyCount() }
    }

    private var allowance: DailyDialogAllowance {
        switch self {
        case .limitedDownload: .transferAlmostFullLimitedDownload
        case .limitedStreaming: .transferAlmostFullLimitedStreaming
        }
    }
}
