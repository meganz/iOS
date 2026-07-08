import Foundation

/// Resolves the wall-clock instant a transfer finished, keyed by transfer tag.
///
/// `MEGATransfer.updateTime` has no defined epoch, so the finish moment can't be
/// read off the transfer snapshot. Instead it is captured live (`Date()` at the
/// finish event) and kept in memory for as long as the matching SDK completed
/// transfer entry exists.
package protocol TransferFinishDateProviding: Sendable {
    /// The recorded finish instant for `tag`, or `nil` if none was captured.
    func finishDate(forTag tag: Int) -> Date?

    /// Stores `date` as the finish instant for `tag` only if none is recorded yet,
    /// and returns the effective value. Set-if-absent makes recording idempotent:
    /// the app-lifetime recorder and the on-screen provider observe the same finish
    /// event from independent streams, so whichever processes it first wins and the
    /// other is a no-op. They process the same instant, so the result is stable.
    @discardableResult
    func recordIfAbsent(tag: Int, date: Date) -> Date

    /// Removes dates whose SDK completed-transfer entries were cleared.
    func removeDates(forTags tags: Set<Int>)
}
