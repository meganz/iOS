enum RecentActionBucketItemsEditingState {
    case inactive
    case active(selectedCount: Int)
}

struct RecentActionBucketItemsNavigationTitle {
    enum TitleType {
        /// Editing is inactive, associated value is bucket nodes count
        case all(Int)
        /// While editing with some items selected, associated value is selected nodes count
        case selected(Int)
    }
    
    enum SubtitleType {
        /// Editing is inactive, associated values are parent folder name and bucket nodes count
        case addedBy(String, Int)
        /// While editing, do not show subtitle.
        case none
    }
    
    let title: TitleType
    let subtitle: SubtitleType
}

protocol RecentActionBucketItemsTitleUseCaseProtocol: Sendable {
    func title(
        for bucket: RecentActionBucketEntity,
        editingState: RecentActionBucketItemsEditingState
    ) -> RecentActionBucketItemsNavigationTitle
}

struct RecentActionBucketItemsTitleUseCase: RecentActionBucketItemsTitleUseCaseProtocol {
    func title(
        for bucket: RecentActionBucketEntity,
        editingState: RecentActionBucketItemsEditingState
    ) -> RecentActionBucketItemsNavigationTitle {
        let title: RecentActionBucketItemsNavigationTitle.TitleType
        let subtitle: RecentActionBucketItemsNavigationTitle.SubtitleType
        
        switch editingState {
        case let .active(selectedCount):
            title = .selected(selectedCount)
            subtitle = .none
        case .inactive:
            title = .all(bucket.nodes.count)
            subtitle = if let parentFolderName = bucket.parent?.name {
                .addedBy(parentFolderName, bucket.nodes.count)
            } else {
                .none
            }
        }
        
        return RecentActionBucketItemsNavigationTitle(title: title, subtitle: subtitle)
    }
}
