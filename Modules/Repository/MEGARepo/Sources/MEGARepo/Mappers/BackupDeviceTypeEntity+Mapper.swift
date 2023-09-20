import MEGADomain

extension BackupDeviceTypeEntity {
    public func toRegexString() -> String {
        switch self {
        case .win: return "(?i)win|desktop"
        case .linux: return "(?i)linux|debian|ubuntu|centos"
        case .drive: return "(?i)ext|drive"
        case .mac: return "(?i)mac|darwin"
        case .android: return "(?i)android"
        case .iphone: return "(?i)iphone"
        case .defaultMobile: return "(?i)mobile"
        case .defaultPc: return "(?i)pc"
        }
    }
    
    public func priority() -> Int {
        switch self {
        case .android: return 8
        case .iphone: return 7
        case .mac: return 6
        case .win: return 5
        case .linux: return 4
        case .drive: return 3
        case .defaultMobile: return 2
        case .defaultPc: return 1
        }
    }
}
