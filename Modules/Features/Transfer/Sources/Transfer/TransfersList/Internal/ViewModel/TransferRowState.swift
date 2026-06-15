import Foundation
import MEGADomain
import Search

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

    public let id: ResultId
    public let fileName: String
    public let direction: Direction
    public var status: Status
    public var progress: Double
    public var transferredBytes: Int64
    public var totalBytes: Int64
    public var speed: Int64
    public var subtitle: String
    public var errorDescription: String?

    /// File system path shown on the Completed row's second line: the destination
    /// folder's cloud path for uploads, or the local destination folder for
    /// downloads. `nil` on tabs that don't render it (e.g. Active).
    public var location: String?
}
