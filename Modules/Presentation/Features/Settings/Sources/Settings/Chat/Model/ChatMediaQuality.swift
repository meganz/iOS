import MEGAL10n

/// This object is used to represent different values of media quality when upload files to chat.
/// It is used for image and video, and represent the local stored values in the device.
public enum ChatMediaQuality: Identifiable, Sendable {
    case auto
    case original
    case optimised
    case low
    case medium
    case high
    
    public var id: Int {
        switch self {
        case .auto: 0
        case .original: 1
        case .optimised: 2
        case .low: 3
        case .medium: 4
        case .high: 5
        }
    }
    
    var localisedName: String {
        switch self {
        case .auto: Strings.Localizable.Media.Quality.automatic
        case .original: Strings.Localizable.Media.Quality.original
        case .optimised: Strings.Localizable.Media.Quality.optimised
        case .low: Strings.Localizable.Media.Quality.low
        case .medium: Strings.Localizable.Media.Quality.medium
        case .high: Strings.Localizable.Media.Quality.high
        }
    }
    
    var localisedDescription: String? {
        switch self {
        case .auto: Strings.Localizable.Settings.Chat.MediaQuality.Image.Option.auto
        case .original: Strings.Localizable.Settings.Chat.MediaQuality.Image.Option.original
        case .optimised: Strings.Localizable.Settings.Chat.MediaQuality.Image.Option.optimised
        default: nil
        }
    }

    public static func imageQualityOptions() -> [ChatMediaQuality] {
        [.auto, .original, .optimised]
    }
    
    public static func videoQualityOptions() -> [ChatMediaQuality] {
        [.low, .medium, .high, .original]
    }
}
