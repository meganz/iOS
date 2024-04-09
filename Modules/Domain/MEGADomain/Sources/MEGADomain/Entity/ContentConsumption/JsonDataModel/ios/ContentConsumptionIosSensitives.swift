import Foundation
import MEGASwift

public struct ContentConsumptionIosSensitives: Codable, Sendable, Equatable {
    public var showHiddenNodes: Bool
    
    static let `default`: Self = .init(showHiddenNodes: false)
    
    enum CodingKeys: String, CodingKey {
        case showHiddenNodes
    }
    
    public init(showHiddenNodes: Bool) {
        self.showHiddenNodes = showHiddenNodes
    }
    
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.showHiddenNodes = try container.decodeIfPresent(for: .showHiddenNodes) ?? Self.default.showHiddenNodes
    }
}
