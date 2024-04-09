import Foundation

public struct ContentConsumptionEntity: Codable, Sendable, Equatable {
    public let ios: ContentConsumptionIos
    
    static let `default`: Self = .init(ios: .default)
    
    enum CodingKeys: String, CodingKey {
        case ios
    }
    
    public init(ios: ContentConsumptionIos) {
        self.ios = ios
    }
    
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let defaultValues = Self.default
        self.ios = try container.decodeIfPresent(for: .ios) ?? defaultValues.ios
    }
}
