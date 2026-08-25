import MEGAUIComponent

@MainActor
public final class PhotoHeaderSortViewModel {
    let config: SortHeaderConfig
    let currentSortOrder: () -> MEGAUIComponent.SortOrder
    let onSortOrderChanged: (MEGAUIComponent.SortOrder) -> Void
    
    public init(config: SortHeaderConfig, currentSortOrder: @escaping () -> MEGAUIComponent.SortOrder, onSortOrderChanged: @escaping (MEGAUIComponent.SortOrder) -> Void) {
        self.config = config
        self.currentSortOrder = currentSortOrder
        self.onSortOrderChanged = onSortOrderChanged
    }
}

extension PhotoHeaderSortViewModel: Equatable {
    nonisolated public static func == (lhs: PhotoHeaderSortViewModel, rhs: PhotoHeaderSortViewModel) -> Bool {
        lhs.config == rhs.config
    }
}

public enum PhotoSectionHeaderType: Sendable, Equatable {
    case photoDate
    case sort(PhotoHeaderSortViewModel)
    /// No section header at all. Use when the surrounding screen already shows its own header
    case none
}

public enum PhotoGlobalHeaderType: Sendable, Equatable {
    /// Sort control on the left, grid zoom control on the right. The date is left to the
    /// per-section headers.
    case sortAndZoom(PhotoHeaderSortViewModel)
    /// Date of the top-most visible section on the left, grid zoom control on the right.
    case dateAndZoom
    case none
}

extension PhotoGlobalHeaderType {
    /// Whether the pinned global header renders the date of the top-most visible section.
    ///
    /// When it does, the per-section date headers are redundant: the first one is dropped and the
    /// rest pin to the top, deliberately hidden behind the global header. When it does not, they are
    /// the only place the date appears, so they must stay visible and scroll with the grid instead.
    var showsSectionDate: Bool {
        self == .dateAndZoom
    }
}
