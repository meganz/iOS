/// Why a public link could not be opened. Lives in the domain layer so every link feature
/// can map SDK errors onto it without depending on another feature.
public enum LinkUnavailableReason: Error, Sendable, Equatable {
    case downETD
    case userETDSuspension
    case copyrightSuspension
    case generic
    case expired
}
