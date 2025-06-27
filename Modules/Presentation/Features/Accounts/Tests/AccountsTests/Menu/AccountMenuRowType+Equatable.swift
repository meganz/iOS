@testable import Accounts

extension AccountMenuOption.AccountMenuRowType: Equatable {
    public static func == (
        lhs: AccountMenuOption.AccountMenuRowType,
        rhs: AccountMenuOption.AccountMenuRowType
    ) -> Bool {
        switch (lhs, rhs) {
        case (.disclosure, .disclosure):
            return true
        case (.externalLink, .externalLink):
            return true
        case let (.withButton(title1, _), .withButton(title2, _)):
            return title1 == title2
        default:
            return false
        }
    }
}
