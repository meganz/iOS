@testable import MEGA
import MEGADomain

extension UserAlertEntity {

    static var random: Self {
        return .init(identifier: .random(in: 0...1),
                     isSeen: .random(),
                     isRelevant: .random(),
                     alertType: UserAlertTypeEntity.allCases.randomElement() ?? .unknown,
                     alertTypeString: "",
                     userHandle: nil,
                     nodeHandle: nil,
                     email: nil,
                     path: nil,
                     name: nil,
                     heading: nil,
                     title: nil,
                     isOwnChange: .random())
    }
}
