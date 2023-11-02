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
            type: .node,
            thumbnailPreviewInfo: .init(
                id: "1",
                displayMode: .file,
                title: "File title",
                subtitle: "Info",
                iconIndicatorPath: nil,
                duration: "2:00",
                isVideoIconHidden: true,
                hasThumbnail: true,
                thumbnailImageData: { .init() },
                propertiesData: { [] },
                downloadVisibilityData: { false }
            )
        )
    }
    public static func resultWith(id: ResultId) -> Self {
        .resultWith(
            id: id,
            title: "title_\(id)"
        )
    }
}
