/// This class facilitates communication between the parent of the search feature and
///  the search view model.
///  Acts as an abstraction to not pollute view model interface with many closures and makes testing easier
import Foundation
import MEGAUIComponent
import UIKit

public class SearchBridge {
    let selection: (SearchResultSelection) -> Void
    let context: (SearchResult, UIButton) -> Void
    let sortingOrder: () -> MEGAUIComponent.SortOrder
    let updateSortOrder: (MEGAUIComponent.SortOrder) -> Void
    private let chipTapped: (SearchChipEntity, Bool) -> Void
    private let chipPickerShowedHandler: @Sendable (SearchChipEntity) -> Void

    public init(
        selection: @escaping (SearchResultSelection) -> Void,
        context: @escaping (SearchResult, UIButton) -> Void,
        chipTapped: @escaping (SearchChipEntity, Bool) -> Void,
        sortingOrder: @escaping () -> MEGAUIComponent.SortOrder,
        updateSortOrder: @escaping (MEGAUIComponent.SortOrder) -> Void,
        chipPickerShowedHandler: @Sendable @escaping (SearchChipEntity) -> Void
    ) {
        self.selection = selection
        self.context = context
        self.chipTapped = chipTapped
        self.sortingOrder = sortingOrder
        self.updateSortOrder = updateSortOrder
        self.chipPickerShowedHandler = chipPickerShowedHandler
    }
    
    func chip(tapped chip: SearchChipEntity, isSelected: Bool) {
        chipTapped(chip, isSelected)
    }

    func chipPickerShowed(from chip: SearchChipEntity) {
        chipPickerShowedHandler(chip)
    }

    public var queryChanged: (String) -> Void = { _ in }
    public var queryCleaned: () -> Void = { }
    public var searchCancelled: () -> Void = { }
    public var updateBottomInset: (CGFloat) -> Void = { _ in  }
    public var layoutChanged: (PageLayout) -> Void = { _ in  }
     
    public var selectionChanged: (Set<ResultId>) -> Void = { _ in }
    public var editingChanged: (Bool) -> Void = { _ in }
    public var editingCancelled: () -> Void = { }
    public var viewModeChanged: @MainActor (SearchResultsViewMode) -> Void = { _ in }
}
