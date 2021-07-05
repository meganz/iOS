@testable import MEGA

extension UserAlert {

    static var random: Self {
        return .init(identifier: .random(in: 0...1),
                     isSeen: .random(),
                     isRelevant: .random(),
                     alertType: AlertType(rawValue: Int.random(in: 0..<21)),
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
