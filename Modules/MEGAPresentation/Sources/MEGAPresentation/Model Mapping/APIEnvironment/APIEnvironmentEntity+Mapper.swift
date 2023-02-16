import MEGADomain

extension APIEnvironmentEntity: RawRepresentable {
    public typealias RawValue = String
    
    public init?(rawValue: String) {
        switch rawValue {
        case "Production": self = .production
        case "Staging": self = .staging
        case "Staging444": self = .staging444
        case "Sandbox3": self = .sandbox3
        default:
            return nil
        }
    }
    
    public var rawValue: String {
        switch self {
        case .production: return "Production"
        case .staging: return "Staging"
        case .staging444: return "Staging:444"
        case .sandbox3: return "Sandbox3"
        }
    }
    
    public func toEnvironmentCode() -> Int {
        switch self {
        case .production: return 0
        case .staging: return 1
        case .staging444: return 2
        case .sandbox3: return 3
        }
    }
}
