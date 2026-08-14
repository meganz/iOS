import Foundation
import MEGADomain

/// Reads and edits the showings ``PromoDialogReshowAllowance`` has stored for one account.
/// **QA affordance only** — production code must never build one.
///
/// It reads the `UserDefaults` suite rather than going through an allowance: a stored showing is keyed on the
/// campaign it was for (see ``PromoDialogReshowKey``), and QA has no campaign to hand — it needs whatever is
/// stored, including showings left behind by campaigns that have since finished.
public struct PromoDialogReshowQAStore {
    private let accountHandle: HandleEntity
    private let userDefaults: UserDefaults

    public init(accountHandle: HandleEntity) {
        self.init(
            accountHandle: accountHandle,
            userDefaults: UserDefaults(suiteName: PromoDialogReshowAllowance.suiteName) ?? .standard
        )
    }

    init(accountHandle: HandleEntity, userDefaults: UserDefaults) {
        self.accountHandle = accountHandle
        self.userDefaults = userDefaults
    }

    /// Every showing stored for this account, as `"<campaignId> @ <date>"`, or empty when the dialog has never
    /// been shown to it.
    public var storedRecordDescriptions: [String] {
        storedRecords.map { "\($0.campaignId) @ \($0.shownDate.formatted())" }
    }

    /// Forgets every showing stored for this account, so the next app open shows the dialog again whichever
    /// campaign is live.
    public func reset() {
        for record in storedRecords {
            userDefaults.removeObject(forKey: record.key)
        }
    }

    /// Backdates every stored showing, so QA can cross a reshow interval without waiting it out.
    public func backdateShownDates(by interval: TimeInterval) {
        for record in storedRecords {
            userDefaults.set(record.shownDate - interval, forKey: record.key)
        }
    }

    /// The stored showings, ordered by campaign so the QA screen does not reshuffle between reads.
    private var storedRecords: [StoredRecord] {
        let prefix = PromoDialogReshowKey.shownDatePrefix(accountHandle: accountHandle)
        return userDefaults.dictionaryRepresentation()
            .compactMap { key, value -> StoredRecord? in
                guard key.hasPrefix(prefix), let shownDate = value as? Date else { return nil }
                return StoredRecord(key: key, campaignId: String(key.dropFirst(prefix.count)), shownDate: shownDate)
            }
            .sorted { $0.campaignId < $1.campaignId }
    }

    /// One showing, as it is stored: the key it lives under, the campaign it was for, and when it happened.
    private struct StoredRecord {
        let key: String
        let campaignId: String
        let shownDate: Date
    }
}
