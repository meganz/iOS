import Search

extension SearchQueryEntity {
    
    /// this checks if we are doing initial search query (or empty search query ) and should results contents of the home folder
    public var isRootDefaultPreviewRequest: Bool {
        self == .initialRootQuery
    }
    /// default search query performed on the appear of the screen results screen
    public static var initialRootQuery: Self {
        SearchQueryEntity(query: "", sorting: .init(key: .name), mode: .home, isSearchActive: false, chips: [])
    }
}

extension SearchResultsEntity {
    /// used as results return when no root folder of the account is found
    ///  we try to get root folder when performing initial or empty search query
    public static var empty: Self {
        .init(results: [], availableChips: [], appliedChips: [])
    }
}
