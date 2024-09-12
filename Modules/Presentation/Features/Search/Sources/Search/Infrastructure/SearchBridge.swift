/// This class facilitates communication between the parent of the search feature and
///  the search view model.
///  Acts as an abstraction to not pollute view model interface with many closures and makes testing easier
import Foundation
import UIKit

public class SearchBridge {
    let selection: (SearchResultSelection) -> Void
    let context: (SearchResult, UIButton) -> Void
    let resignKeyboard: () -> Void
    let sortingOrder: () async -> SortOrderEntity
    private let chipTapped: (SearchChipEntity, Bool) -> Void
    
    public init(
        selection: @escaping (SearchResultSelection) -> Void,
        context: @escaping (SearchResult, UIButton) -> Void,
        resignKeyboard: @escaping () -> Void,
        chipTapped: @escaping (SearchChipEntity, Bool) -> Void,
        sortingOrder: @escaping () async -> SortOrderEntity
    ) {
        self.selection = selection
        self.context = context
        self.chipTapped = chipTapped
        self.resignKeyboard = resignKeyboard
        self.sortingOrder = sortingOrder
    }
    
    func chip(tapped chip: SearchChipEntity, isSelected: Bool) {
        chipTapped(chip, isSelected)
    }
    
    public var queryChanged: (String) -> Void = { _ in }
    public var queryCleaned: () -> Void = { }
    public var searchCancelled: () -> Void = { }
    public var updateBottomInset: (CGFloat) -> Void = { _ in  }
    public var layoutChanged: (PageLayout) -> Void = { _ in  }
     
    public var selectionChanged: (Set<ResultId>) -> Void = { _ in }
    public var editingChanged: (Bool) -> Void = { _ in }
    public var editingCancelled: () -> Void = { }
}
