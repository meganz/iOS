import Foundation
import MEGASwift

public struct ContentConsumptionIos: Codable, Sendable, Equatable {
    public var timeline: ContentConsumptionIosTimeline
    public var sensitives: ContentConsumptionIosSensitives
    
    static let `default`: Self = .init(timeline: .default, sensitives: .default)
    
    enum CodingKeys: String, CodingKey {
        case timeline, sensitives
    }
    
    public init(timeline: ContentConsumptionIosTimeline, sensitives: ContentConsumptionIosSensitives) {
        self.timeline = timeline
        self.sensitives = sensitives
    }
    
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.timeline = try container.decodeIfPresent(for: .timeline) ?? .default
        self.sensitives = try container.decodeIfPresent(for: .sensitives) ?? .default
    }
}
