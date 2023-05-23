import MEGADomain

extension ExtensionsAnalyticsEventEntity: AnalyticsEventProtocol {
    var code: Int {
        switch self {
        case .withoutNoDDatabase: return 99316
        }
    }
    
    var description: String {
        switch self {
        case .withoutNoDDatabase: return "Extension without NoD database"
        }
    }

}
