import MEGASwift
import MEGASwiftUI
import Search
import SwiftUI

public final class MockContentUnavailableViewModelProvider: @unchecked Sendable, ContentUnavailableViewModelProviding {

    public var emptyViewModel: ContentUnavailableViewModel
    public var emptyViewModelFuncCalls = [(query: SearchQuery,
                                   appliedChips: [SearchChipEntity],
                                   config: SearchConfig)]()

    public init(
        emptyViewModel: ContentUnavailableViewModel = .init(
            image: SearchConfig.EmptyViewAssets.testAssets.image,
            title: SearchConfig.EmptyViewAssets.testAssets.title,
            font: .body,
            titleTextColor: SearchConfig.EmptyViewAssets.testAssets.titleTextColor
        )
    ) {
        self.emptyViewModel = emptyViewModel
    }

    public func emptyViewModel(
        query: SearchQuery,
        appliedChips: [SearchChipEntity],
        config: SearchConfig
    ) -> ContentUnavailableViewModel {
        defer {
            emptyViewModelFuncCalls.append((query: query, appliedChips: appliedChips, config: config))
        }
        return self.emptyViewModel
    }
}
