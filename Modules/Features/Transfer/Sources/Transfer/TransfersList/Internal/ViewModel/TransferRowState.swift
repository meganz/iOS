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

    private static let byteFormatStyle = ByteCountFormatStyle(style: .file)
}
