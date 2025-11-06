import MEGADomain

public enum PlaylistContentSupportedSortOrderPolicy {
    public static var supportedSortOrders: [SortOrderEntity] {
        [
            .defaultAsc,
            .defaultDesc,
            .modificationAsc,
            .modificationDesc
        ]
    }
}
