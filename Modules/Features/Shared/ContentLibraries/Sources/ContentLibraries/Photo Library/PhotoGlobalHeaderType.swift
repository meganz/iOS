import Combine
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

public enum PhotoGlobalHeaderType {
    case sort(PhotoHeaderSortViewModel)
    case dateAndZoom
}
