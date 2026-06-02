import Foundation
import MEGADomain
import MEGAFoundation
import Search

/// Maps `TransferEntity` from the Domain layer into the dual representations
/// used by the new Transfers screen:
///
/// - `SearchResult` (carried through the Search list pipeline; identifies the row
///   and routes it to the transfer row dispatch via `ResultType.transfer`).
/// - `TransferRowState` (the rich UI payload stored in the per-row VM inside
///   `TransferRegistry`; carries the fields the row view actually renders).
public enum TransferEntityMapper {

    public static func resultId(for entity: TransferEntity) -> ResultId {
        ResultId(bitPattern: Int64(entity.tag))
    }

    public static func searchResult(for entity: TransferEntity) -> SearchResult {
        let id = resultId(for: entity)
        let name = entity.fileName ?? "Transfer #\(entity.tag)"
        return SearchResult(
            id: id,
            isFolder: entity.isFolderTransfer,
            backgroundDisplayMode: .icon,
            title: name,
            note: nil,
            tags: [],
            isSensitive: false,
            hasThumbnail: false,
            description: { _ in "" },
            type: .transfer,
            properties: [],
            thumbnailImageData: { Data() },
            swipeActions: { _ in [] }
        )
    }

    /// - Parameter location: file system path for the Completed row's second line,
    ///   resolved by the Data adapter (upload destination cloud path or download
    ///   local folder). `nil` for tabs that don't render it.
    public static func rowState(for entity: TransferEntity, location: String? = nil) -> TransferRowState {
        let direction = direction(for: entity.type)
        let status = status(for: entity.state)
        let progress = progress(for: entity)
        let transferredBytes = Int64(entity.transferredBytes)
        let totalBytes = Int64(entity.totalBytes)
        let speed = Int64(entity.speed)
        return TransferRowState(
            id: resultId(for: entity),
            fileName: entity.fileName ?? "Transfer #\(entity.tag)",
            direction: direction,
            status: status,
            progress: progress,
            transferredBytes: transferredBytes,
            totalBytes: totalBytes,
            speed: speed,
            subtitle: subtitle(
                direction: direction,
                status: status,
                progress: progress,
                transferredBytes: transferredBytes,
                totalBytes: totalBytes,
                speed: speed,
                completionDate: completionDateString(for: entity)
            ),
            errorDescription: entity.lastErrorExtended.map { String(describing: $0) },
            location: location
        )
    }

    private static let byteFormatStyle = ByteCountFormatStyle(style: .file)

    private static func completionDateString(for entity: TransferEntity) -> String? {
        guard let date = entity.updateTime else { return nil }
        return DateFormatter.dateMediumTimeShort().localisedString(from: date)
    }

    private static func subtitle(
        direction: TransferRowState.Direction,
        status: TransferRowState.Status,
        progress: Double,
        transferredBytes: Int64,
        totalBytes: Int64,
        speed: Int64,
        completionDate: String?
    ) -> String {
        let arrow = direction == .upload ? "↑" : "↓"
        let percent = Int((progress * 100).rounded())
        let done = byteFormatStyle.format(transferredBytes)
        let total = byteFormatStyle.format(totalBytes)
        switch status {
        case .active:
            let speedText = byteFormatStyle.format(speed)
            return "\(arrow) \(percent)% · \(done) of \(total) · \(speedText)/s"
        case .paused:
            return "\(arrow) \(percent)% · \(done) of \(total) · Paused"
        case .queued:
            return "\(arrow) Queued"
        case .failed:
            return "\(arrow) Failed"
        case .cancelled:
            return "\(arrow) Cancelled"
        case .completed:
            guard let completionDate else { return "\(arrow) \(total)" }
            return "\(arrow) \(total) · \(completionDate)"
        }
    }

    private static func direction(for type: TransferTypeEntity) -> TransferRowState.Direction {
        type == .upload ? .upload : .download
    }

    private static func status(for state: TransferStateEntity) -> TransferRowState.Status {
        switch state {
        case .none, .queued: .queued
        case .active, .retrying, .completing: .active
        case .paused: .paused
        case .complete: .completed
        case .failed: .failed
        case .cancelled: .cancelled
        }
    }

    private static func progress(for entity: TransferEntity) -> Double {
        guard entity.totalBytes > 0 else { return 0 }
        return min(1.0, Double(entity.transferredBytes) / Double(entity.totalBytes))
    }
}
