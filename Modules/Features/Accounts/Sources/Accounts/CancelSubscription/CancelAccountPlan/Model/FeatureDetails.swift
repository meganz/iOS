import UIKit

public struct FeatureDetails: Identifiable {
    public let type: FeatureType
    public let title: String
    public let freeText: String?
    public let freeIcon: UIImage?
    public let proText: String?
    public let proIcon: UIImage?
    
    public var id: String {
        title
    }
    
    init(
        type: FeatureType,
        title: String,
        freeText: String? = nil,
        freeIcon: UIImage? = nil,
        proText: String? = nil,
        proIcon: UIImage? = nil
    ) {
        self.type = type
        self.title = title
        self.freeText = freeText
        self.freeIcon = freeIcon
        self.proText = proText
        self.proIcon = proIcon
    }
}
