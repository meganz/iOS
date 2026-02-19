import Favourites
import MEGADomainMock
import SearchMock
import Testing
@testable import MEGAUIComponent
@testable import Search

@MainActor
struct FavouritesViewModelTests {

    // MARK: - Sort options

    @Test
    func sortHeaderConfigContainsAllExpectedKeys() {
        let sut = makeSUT()
        let keys = sut.searchResultsContainerViewModel.sortHeaderConfig.options.map(\.id)

        #expect(keys.contains(.name))
        #expect(keys.contains(.favourite))
        #expect(keys.contains(.label))
        #expect(keys.contains(.dateAdded))
        #expect(keys.contains(.lastModified))
        #expect(keys.contains(.size))
        #expect(keys.count == 6)
    }

    // MARK: - Initial sort order

    @Test
    func initialSortOrderIsReadFromPreferenceUseCase() {
        let useCase = MockSortOrderPreferenceUseCase(sortOrderEntity: .defaultAsc)
        let sut = makeSUT(sortOrderPreferenceUseCase: useCase)

        let containerVM = sut.searchResultsContainerViewModel
        let sortOrder = containerVM.bridge.sortingOrder()

        #expect(sortOrder == .init(key: .name))
        #expect(useCase.messages.contains(.sortOrder(key: .homeFavourites)))
    }

    // MARK: - Save sort order

    @Test
    func updatingSortOrderCallsSaveOnPreferenceUseCase() async {
        let useCase = MockSortOrderPreferenceUseCase(sortOrderEntity: .defaultAsc)
        let sut = makeSUT(sortOrderPreferenceUseCase: useCase)

        let newSortOrder = MEGAUIComponent.SortOrder(key: .lastModified)
        sut.searchResultsContainerViewModel.bridge.updateSortOrder(newSortOrder)

        #expect(useCase.messages.contains(.save(sortOrder: .modificationAsc, for: .homeFavourites)))
    }

    // MARK: - External sort order monitoring

    @Test
    func initStartsMonitoringSortOrderForHomeFavourites() {
        let useCase = MockSortOrderPreferenceUseCase()
        _ = makeSUT(sortOrderPreferenceUseCase: useCase)

        #expect(useCase.messages.contains(.monitorSortOrder(key: .homeFavourites)))
    }

    // MARK: - Helpers

    private func makeSUT(
        sortOrderPreferenceUseCase: MockSortOrderPreferenceUseCase = MockSortOrderPreferenceUseCase()
    ) -> FavouritesViewModel {
        FavouritesViewModel(
            dependency: .init(
                resultsProvider: MockSearchResultsProviding(),
                contextAction: { _, _ in },
                sortOrderPreferenceUseCase: sortOrderPreferenceUseCase
            )
        )
    }
}
