import Foundation

public enum SlideShowPlayingOrderEntity: Codable, Sendable {
    case shuffled
    case newest
    case oldest
    
    public var value: Int {
        switch self {
        case .shuffled: return 1
        case .newest: return 2
        case .oldest: return 3
        }
    }
    
    public static func type(for value: Int) -> SlideShowPlayingOrderEntity {
        var playingOrder: SlideShowPlayingOrderEntity = .shuffled
        
        switch value {
        case 1: playingOrder = .shuffled
        case 2: playingOrder = .newest
        case 3: playingOrder = .oldest
        default: playingOrder = .shuffled
        }
        
        return playingOrder
    }
}

public enum SlideShowTimeIntervalOptionEntity: Codable {
    case slow
    case normal
    case fast
    
    public var value: Double {
        switch self {
        case .slow: return 8
        case .normal: return 4
        case .fast: return 2
        }
    }
    
    public static func type(for value: Double) -> SlideShowTimeIntervalOptionEntity {
        var interval: SlideShowTimeIntervalOptionEntity = .normal
        
        switch value {
        case 8: interval = .slow
        case 4: interval = .normal
        case 2: interval = .fast
        default: interval = .normal
        }
        
        return interval
    }
}

public struct SlideShowConfigurationEntity: Equatable, Codable {
    public var playingOrder: SlideShowPlayingOrderEntity
    public var timeIntervalForSlideInSeconds: SlideShowTimeIntervalOptionEntity
    public var isRepeat: Bool
    public var includeSubfolders: Bool
    
    public init(playingOrder: SlideShowPlayingOrderEntity, timeIntervalForSlideInSeconds: SlideShowTimeIntervalOptionEntity, isRepeat: Bool, includeSubfolders: Bool) {
        self.playingOrder = playingOrder
        self.timeIntervalForSlideInSeconds = timeIntervalForSlideInSeconds
        self.isRepeat = isRepeat
        self.includeSubfolders = includeSubfolders
    }
}
