public enum RecentlyOpenedNodesErrorEntity: Error, Equatable {
    case couldNotCreateNewBackgroundContext
    case couldNotSaveNodeFailToGetDataToSave
    case couldNotFindNodeForFingerprint
    case couldNotClearRecentlyOpenedNode
}
