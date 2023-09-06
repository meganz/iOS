import Search

extension SearchQueryEntity {
    public static func query(_ string: String) -> Self {
        .init(
            query: string,
            sorting: .automatic,
            mode: .home,
            chips: []
        )
    }
}
