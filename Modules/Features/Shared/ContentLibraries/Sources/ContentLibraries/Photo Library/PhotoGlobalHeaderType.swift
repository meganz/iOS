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
}

public enum PhotoGlobalHeaderType: Sendable, Equatable {
    case sort(PhotoHeaderSortViewModel)
    case dateAndZoom
    case none
}
