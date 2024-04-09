import Foundation

public struct ContentConsumptionEntity: Codable, Sendable, Equatable {
    public var ios: ContentConsumptionIos
    public var sensitives: ContentConsumptionSensitives
    
    static let `default`: Self = .init(ios: .default, sensitives: .default)
    
    enum CodingKeys: String, CodingKey {
        case ios
        case sensitives
    }
    
    public init(ios: ContentConsumptionIos, sensitives: ContentConsumptionSensitives) {
        self.ios = ios
        self.sensitives = sensitives
    }
    
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let defaultValues = Self.default
        self.ios = try container.decodeIfPresent(for: .ios) ?? defaultValues.ios
        self.sensitives = try container.decodeIfPresent(for: .sensitives) ?? defaultValues.sensitives
    }
}
