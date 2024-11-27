public enum CollisionResolutionEntity: Sendable {
    case overwrite // Overwrite the existing one
    case renameNewWithSuffix // Rename the new one with suffix (1), (2), and etc.
    case renameOldWithSuffix // Rename the existing one with suffix .old1, old2, and etc.
}
