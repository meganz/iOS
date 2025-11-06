public struct ItemAssets {
    public let iconName: String
    public let statusAssets: StatusAssets
    public let defaultName: String?
    
    public init(
        iconName: String,
        statusAssets: StatusAssets,
        defaultName: String? = nil
    ) {
        self.iconName = iconName
        self.statusAssets = statusAssets
        self.defaultName = defaultName
    }
}
