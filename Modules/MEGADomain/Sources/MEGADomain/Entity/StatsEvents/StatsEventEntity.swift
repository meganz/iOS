import Foundation

public enum StatsEventEntity {
    case clickMediaDiscovery
    case stayOnMediaDiscoveryOver10s
    case stayOnMediaDiscoveryOver30s
    case stayOnMediaDiscoveryOver60s
    case stayOnMediaDiscoveryOver180s
    
    public var message: String {
        let value: String
        
        switch self {
        case .clickMediaDiscovery: value = "Media Discovery Option Tapped"
        case .stayOnMediaDiscoveryOver10s: value = "Stay on Media Discovery over 10s"
        case .stayOnMediaDiscoveryOver30s: value = "Stay on Media Discovery over 30s"
        case .stayOnMediaDiscoveryOver60s: value = "Stay on Media Discovery over 60s"
        case .stayOnMediaDiscoveryOver180s: value = "Stay on Media Discovery over 180s"
        }
        
        return value
    }
}
