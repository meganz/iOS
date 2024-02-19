import MEGADomain

// this enum is used when negotiating if given folder should
// have a media discovery option available in the context menu (if there are any media)
// or if it should be shown automatically (folder only having images inside)
enum CloudDriveViewControllerMediaCheckerMode {
    case containsExclusivelyMedia
    case containsSomeMedia

    /// checks if children of  given node are all visual media (video/image) or if there is at least one media element
    /// used to decide if we need to show the media discovery mode automatically and if media discovery
    /// view mode option should be shown at all in the context menu
    func makeVisualMediaChecker(
        nodeSource: NodeSource,
        nodeUseCase: some NodeUseCaseProtocol
    ) -> () async -> Bool {
        switch nodeSource {
        case .node(let provider):
            // in here we produce a closure that can asynchronously check
            // if given folder node contains only media (videos/images)
            return {
                guard
                    let node = provider(),
                    let children = await nodeUseCase.childrenOf(node: node)
                else { return false }

                switch self {
                case .containsExclusivelyMedia:
                    return children.containsOnlyVisualMedia()
                case .containsSomeMedia:
                    return children.containsVisualMedia()
                }
            }
        case .recentActionBucket:
            return { false }
        }
    }
}
