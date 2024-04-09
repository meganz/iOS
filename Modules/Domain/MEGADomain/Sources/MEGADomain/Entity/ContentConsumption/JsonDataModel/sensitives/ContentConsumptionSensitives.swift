import Foundation
import MEGASwift

public struct ContentConsumptionSensitives: Codable, Sendable, Equatable {
    
    public var onboarded: Bool
    
    static let `default`: Self = .init(onboarded: false)
    
    public init(onboarded: Bool) {
        self.onboarded = onboarded
    }
    
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.onboarded = try container.decodeIfPresent(for: .onboarded) ?? Self.default.onboarded
    }
}
