import Foundation
import MEGADomain
import MEGAFoundation
import MEGAL10n

/// UI-shape snapshot of a single transfer for the new Transfers screen.
///
/// Produced by `TransferEntityMapper` once per inbound `TransferEntity` and stored
/// inside the per-row `TransferRowViewModel`. The mapper is the only place that
/// translates `TransferStateEntity` / `TransferTypeEntity` into UI vocabulary.
public struct TransferRowState: Sendable, Equatable {
    public enum Direction: Sendable, Equatable {
        case upload
        case download
    }

    public enum Status: Sendable, Equatable {
        case queued
        case active
        case paused
        case completed
        case failed
        case cancelled
    }

    /// The SDK transfer tag, unique per transfer for the app session.
    public let id: Int
    public let fileName: String
    public let direction: Direction
    public var status: Status
    public var progress: Double
    public var transferredBytes: Int64
    public var totalBytes: Int64
    public var speed: Int64
    public var finishDate: Date?
    public var errorDescription: String?

    /// File system path shown on the Completed row's second line: the destination
    /// folder's cloud path for uploads, or the local destination folder for
    /// downloads. `nil` on tabs that don't render it (e.g. Active).
    public var location: String?

    /// Whether the Completed row offers `View in folder`. `false` for downloads saved
    /// to Photos, which have no deep-linkable folder. Only meaningful on the Completed
    /// tab; defaults to `true` everywhere else.
    public var canViewInFolder: Bool = true

    /// Whether the row can be re-queued: a Failed-tab substate whose source is still
    /// readable. Uploads staged with a temporary source (e.g. Photos picker, share
    /// extension) lose their file when the transfer finishes — even cancelled or
    /// failed — so retrying them can only fail again; such rows offer no retry.
    /// Drives the leading retry swipe and the sheet's Retry item.
    public var isRetryable: Bool = false

    public var subtitle: String {
        let arrow = direction == .upload ? "↑" : "↓"
        switch status {
        case .active:
            let percent = Int((progress * 100).rounded())
            let done = Self.byteFormatStyle.format(transferredBytes)
            let total = Self.byteFormatStyle.format(totalBytes)
            let speedText = Self.byteFormatStyle.format(speed)
            return "\(arrow) \(percent)% · \(done) of \(total) · \(speedText)/s"
        case .paused:
            let percent = Int((progress * 100).rounded())
            let done = Self.byteFormatStyle.format(transferredBytes)
            let total = Self.byteFormatStyle.format(totalBytes)
            return "\(arrow) \(percent)% · \(done) of \(total) · Paused"
        case .queued:
            return "\(arrow) Queued"
        case .failed:
            return "\(arrow) \(Strings.Localizable.Transfers.Tab.failed)"
        case .cancelled:
            return "\(arrow) \(Strings.Localizable.cancelled)"
        case .completed:
            let total = "\(arrow) \(Self.byteFormatStyle.format(totalBytes))"
            guard let finishDate else { return total }
            return "\(total) · \(DateFormatter.dateMediumTimeShort().localisedString(from: finishDate))"
        }
    }

    // MARK: - Accessibility

    /// The row's name and state, read together as `<file name>, <state>`.
    var accessibilityLabel: String {
        [fileName, accessibilityStatus].joined(separator: ", ")
    }

    /// The progress, spoken after the label as "48 percent" — the row reads as
    /// `<file name>, <state>, <progress>`.
    ///
    /// Empty on rows with no progress to report: a queued transfer has made none,
    /// and a terminal row's percentage is implied by its state.
    var accessibilityValue: String {
        switch status {
        case .active, .paused:
            "\(Int((progress * 100).rounded()))%"
        case .queued, .completed, .failed, .cancelled:
            ""
        }
    }

    private var accessibilityStatus: String {
        switch status {
        case .active: Strings.Localizable.Transfers.Tab.active
        case .queued: Strings.Localizable.queued
        case .paused: Strings.Localizable.paused
        case .completed: Strings.Localizable.Transfers.Tab.completed
        case .failed: Strings.Localizable.Transfers.Tab.failed
        case .cancelled: Strings.Localizable.cancelled
        }
    }

    private static let byteFormatStyle = ByteCountFormatStyle(style: .file)
}
