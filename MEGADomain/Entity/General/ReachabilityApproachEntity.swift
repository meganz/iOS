import Foundation

/// It tells how current device reachable to networking
enum ReachabilityApproachEntity: Equatable {
    case viaWiFi
    case viaWWAN
    /// It is a undetected or unstable reachability that could potentially exists.
    case unexpected
}

/// An enum tells whether current device reachable to network.
enum NetworkReachabilityEntity: Equatable {
    /// If reachable to network, the enclosed value tells the approach to netnworking.
    case reachable(ReachabilityApproachEntity)
    case unreachable
}
