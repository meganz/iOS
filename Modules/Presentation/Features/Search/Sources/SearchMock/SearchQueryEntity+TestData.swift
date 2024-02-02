import Search

extension SearchQueryEntity {
    public static func query(_ string: String, isSearchActive: Bool) -> Self {
        .init(
            query: string,
            sorting: .automatic,
            mode: .home,
            isSearchActive: isSearchActive,
            chips: []
        )
    }
}
