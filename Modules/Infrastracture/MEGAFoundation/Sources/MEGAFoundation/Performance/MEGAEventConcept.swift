#if DEBUG
import Foundation

/// Used as an adjective to describe another type. Such as "Warning", or "Error".
/// This is also may contain simple shapes or the alphabet, for uses like providing images that
/// help explain the type of thing being drawn.
public enum MEGAEventConcept: String {
    case success = "Success"
    case failure = "Failure"
    case fault = "Fault"
    case critical = "Critical"
    case error = "Error"
    case debug = "Debug"
    case pedantic = "Pedantic"
    case info = "Info"
    case signpost = "Signpost"
    case veryLow = "Very Low"
    case low = "Low"
    case moderate = "Moderate"
    case high = "High"
    case red = "Red"
    case orange = "Orange"
    case blue = "Blue"
    case purple = "Purple"
    case green = "Green"
}
#endif
