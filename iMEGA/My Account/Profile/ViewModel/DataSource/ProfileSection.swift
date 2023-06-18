import Foundation

enum ProfileSection: Int {
    case profile
    case security
    case plan
    case session
}

enum ProfileSectionRow: Hashable, Equatable {
    case changeName
    case changePhoto
    case changeEmail(isLoading: Bool)
    case phoneNumber
    case changePassword(isLoading: Bool)
    case recoveryKey
    case upgrade
    case role
    case logout
    
    func hash(into hasher: inout Hasher) {
        switch self {
        case .changeName:
            hasher.combine("changeName")
        case .changePhoto:
            hasher.combine("changePhoto")
        case .changeEmail:
            hasher.combine("changeEmail")
        case .phoneNumber:
            hasher.combine("phoneNumber")
        case .changePassword:
            hasher.combine("changePassword")
        case .recoveryKey:
            hasher.combine("recoveryKey")
        case .upgrade:
            hasher.combine("upgrade")
        case .role:
            hasher.combine("role")
        case .logout:
            hasher.combine("logout")
        }
    }
}
