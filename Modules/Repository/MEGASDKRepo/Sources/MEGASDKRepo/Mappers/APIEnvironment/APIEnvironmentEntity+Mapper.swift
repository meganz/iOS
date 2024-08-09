import MEGADomain

extension APIEnvironmentEntity: RawRepresentable {
    public typealias RawValue = String
    
    public init?(rawValue: String) {
        switch rawValue {
        case "Production": self = .production
        case "Staging": self = .staging
        case "bt1444": self = .bt1444
        case "Sandbox3": self = .sandbox3
        default:
            return nil
        }
    }
    
    public var rawValue: String {
        switch self {
        case .production: "Production"
        case .staging: "Staging"
        case .bt1444: "bt1:444"
        case .sandbox3: "Sandbox3"
        }
    }
    
    public func toEnvironmentCode() -> Int {
        switch self {
        case .production: 0
        case .staging: 1
        case .bt1444: 2
        case .sandbox3: 3
        }
    }
}
