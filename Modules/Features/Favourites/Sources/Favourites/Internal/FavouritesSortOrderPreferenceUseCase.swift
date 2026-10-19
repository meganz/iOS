import Combine
import MEGADomain

package protocol FavouritesSortOrderPreferenceUseCaseProtocol {
    func sortOrder() -> SortOrderEntity
    func save(sortOrder: SortOrderEntity)
    func monitorSortOrder() -> AnyPublisher<SortOrderEntity, Never>
}

package struct FavouritesSortOrderPreferenceUseCase: FavouritesSortOrderPreferenceUseCaseProtocol {
    private let sortOrderPreferenceUseCase: any SortOrderPreferenceUseCaseProtocol

    package init(sortOrderPreferenceUseCase: some SortOrderPreferenceUseCaseProtocol) {
        self.sortOrderPreferenceUseCase = sortOrderPreferenceUseCase
    }

    package func sortOrder() -> SortOrderEntity {
        sortOrderPreferenceUseCase.sortOrder(for: .homeFavourites).supportedInFavourites
    }

    package func save(sortOrder: SortOrderEntity) {
        guard sortOrder != self.sortOrder() else { return }
        sortOrderPreferenceUseCase.save(sortOrder: sortOrder, for: .homeFavourites)
    }

    package func monitorSortOrder() -> AnyPublisher<SortOrderEntity, Never> {
        sortOrderPreferenceUseCase
            .monitorSortOrder(for: .homeFavourites)
            .map(\.supportedInFavourites)
            .removeDuplicates()
            .eraseToAnyPublisher()
    }
}

private extension SortOrderEntity {
    // The saved value can be a Favourite sort: an older saved value, or a shared "Same for all"
    // value set on another screen. Favourites has no Favourite sort, so it is read as Name ascending.
    var supportedInFavourites: SortOrderEntity {
        switch self {
        case .favouriteAsc, .favouriteDesc: .defaultAsc
        default: self
        }
    }
}
