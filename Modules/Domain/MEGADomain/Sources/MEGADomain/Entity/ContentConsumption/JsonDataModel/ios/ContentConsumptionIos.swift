import Foundation
import MEGASwift

public struct ContentConsumptionIos: Codable, Sendable, Equatable {
    public let timeline: ContentConsumptionIosTimeline
    
    static let `default`: Self = .init(timeline: .default)
    
    enum CodingKeys: String, CodingKey {
        case timeline
    }
    
    public init(timeline: ContentConsumptionIosTimeline) {
        self.timeline = timeline
    }
    
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.timeline = try container.decodeIfPresent(for: .timeline) ?? .default
    }
}
