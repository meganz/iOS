import MEGADomain

extension MediaDiscoveryAnalyticsEventEntity: AnalyticsEventProtocol {
    var code: Int {
        switch self {
        case .clickMediaDiscovery: return 99304
        case .stayOnMediaDiscoveryOver10s: return 99305
        case .stayOnMediaDiscoveryOver30s: return 99306
        case .stayOnMediaDiscoveryOver60s: return 99307
        case .stayOnMediaDiscoveryOver180s: return 99308
        }
    }
    
    var description: String {
        switch self {
        case .clickMediaDiscovery:
            return "Media Discovery Option Tapped"
        case .stayOnMediaDiscoveryOver10s:
            return "Stay on Media Discovery over 10s"
        case .stayOnMediaDiscoveryOver30s:
            return "Stay on Media Discovery over 30s"
        case .stayOnMediaDiscoveryOver60s:
            return "Stay on Media Discovery over 60s"
        case .stayOnMediaDiscoveryOver180s:
            return "Stay on Media Discovery over 180s"
        }
    }
}
