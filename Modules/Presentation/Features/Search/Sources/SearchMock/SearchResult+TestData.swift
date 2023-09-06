import Search

extension SearchResult {
    public static func resultWith(
        id: ResultId,
        title: String
    ) -> Self {
        return .init(
            id: id,
            title: title,
            description: "subtitle_\(id)",
            properties: [],
            thumbnailImageData: { .init() },
            type: .node
        )
    }
    public static func resultWith(id: ResultId) -> Self {
        .resultWith(
            id: id,
            title: "title_\(id)"
        )
    }
}
