import MEGADomain

extension ExtensionsAnalyticsEventEntity: AnalyticsEventProtocol {
    var code: Int {
        get {
            var value: Int
            switch self {
            case .withoutNoDDatabase: value = 99316
            }
            return value
        }
    }
    
    var description: String {
        get {
            var value: String
            switch self {
            case .withoutNoDDatabase: value = "Extension without NoD database"
            }
            return value
        }
    }

}
