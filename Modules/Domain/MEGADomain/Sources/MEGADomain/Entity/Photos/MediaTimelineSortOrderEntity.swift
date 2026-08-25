/// Sort order for the media timeline: a direction (newest / oldest first) paired with the
/// timestamp column the SDK orders and groups by.
///
/// Deliberately narrower than `SortOrderEntity` on purpose — `groupAllNodesByDate` accepts
/// only the modification-time and media-capture-time orders, and the keyset cursor carries
/// just the one timestamp key belonging to the chosen order, so exposing size / label /
/// favourite here would silently break pagination.
public enum MediaTimelineSortOrderEntity: Sendable, Equatable {
    /// Newest first, by modification time.
    case newest
    /// Oldest first, by modification time.
    case oldest
    /// Newest first, by media capture time.
    case newestByCaptureTime
    /// Oldest first, by media capture time.
    case oldestByCaptureTime
}

extension MediaTimelineSortOrderEntity {
    /// Which timestamp a timeline order sorts and buckets by. The two are not
    /// interchangeable: a file's capture time and its modification time can land on
    /// different days, and only media files carry a capture time at all.
    public enum TimestampBasis: Sendable, Equatable, CaseIterable {
        /// The node's modification time. Every file has one.
        case modificationTime
        /// The capture time the SDK derives for photo / video / audio files.
        case mediaCaptureTime
    }

    public init(newestFirst: Bool, basis: TimestampBasis) {
        switch (newestFirst, basis) {
        case (true, .modificationTime): self = .newest
        case (false, .modificationTime): self = .oldest
        case (true, .mediaCaptureTime): self = .newestByCaptureTime
        case (false, .mediaCaptureTime): self = .oldestByCaptureTime
        }
    }

    public var timestampBasis: TimestampBasis {
        switch self {
        case .newest, .oldest: .modificationTime
        case .newestByCaptureTime, .oldestByCaptureTime: .mediaCaptureTime
        }
    }

    /// True when the order runs newest → oldest.
    public var isNewestFirst: Bool {
        switch self {
        case .newest, .newestByCaptureTime: true
        case .oldest, .oldestByCaptureTime: false
        }
    }

    /// The same direction read against `basis` instead.
    public func applying(_ basis: TimestampBasis) -> Self {
        Self(newestFirst: isNewestFirst, basis: basis)
    }

    /// The opposite direction on the same timestamp — the order a backward keyset page is
    /// fetched in before being reversed back into display order.
    public var flippingDirection: Self {
        Self(newestFirst: !isNewestFirst, basis: timestampBasis)
    }
}
