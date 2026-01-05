import Foundation
import MEGAUIComponent

public struct SearchResultsSortOptionsViewModel {
    public let title: String
    public let sortOptions: [SortOption]
    public typealias TapHandler = (SortOption) -> Void
    let tapHandler: TapHandler?

    public init(
        title: String,
        sortOptions: [SortOption],
        tapHandler: TapHandler? = nil
    ) {
        self.title = title
        self.sortOptions = sortOptions
        self.tapHandler = tapHandler
    }

    public func makeNewViewModel(
        with sortOptions: [SortOption],
        tapHandler: TapHandler?
    ) -> Self {
        .init(title: title, sortOptions: sortOptions, tapHandler: tapHandler)
    }
}
