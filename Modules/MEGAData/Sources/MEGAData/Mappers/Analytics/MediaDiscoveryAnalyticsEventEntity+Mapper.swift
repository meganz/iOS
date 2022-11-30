import MEGADomain

extension MediaDiscoveryAnalyticsEventEntity: AnalyticsEventProtocol {
    var code: Int {
        get {
            var value: Int
            switch self {
            case .clickMediaDiscovery: value = 99304
            case .stayOnMediaDiscoveryOver10s: value = 99305
            case .stayOnMediaDiscoveryOver30s: value = 99306
            case .stayOnMediaDiscoveryOver60s: value = 99307
            case .stayOnMediaDiscoveryOver180s: value = 99308
            }
            return value
        }
    }
    
    var description: String {
        get {
            var value: String
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
}
