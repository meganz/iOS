public struct FeatureDetails: Identifiable {
    public let type: FeatureType
    public let title: String
    public let freeText: String?
    public let freeIconName: String?
    public let proText: String?
    public let proIconName: String?
    
    public var id: String {
        title
    }
    
    init(
        type: FeatureType,
        title: String,
        freeText: String? = nil,
        freeIconName: String? = nil,
        proText: String? = nil,
        proIconName: String? = nil
    ) {
        self.type = type
        self.title = title
        self.freeText = freeText
        self.freeIconName = freeIconName
        self.proText = proText
        self.proIconName = proIconName
    }
}
