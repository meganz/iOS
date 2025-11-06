import Foundation

public struct SearchResultsSortOptionsViewModel {
    let title: String
    let sortOptions: [SearchResultsSortOption]
    public typealias TapHandler = (SearchResultsSortOption) -> Void
    let tapHandler: TapHandler?

    public init(
        title: String,
        sortOptions: [SearchResultsSortOption],
        tapHandler: TapHandler? = nil
    ) {
        self.title = title
        self.sortOptions = sortOptions
        self.tapHandler = tapHandler
    }

    func makeNewViewModel(
        with sortOptions: [SearchResultsSortOption],
        tapHandler: TapHandler?
    ) -> Self {
        .init(title: title, sortOptions: sortOptions, tapHandler: tapHandler)
    }
}
