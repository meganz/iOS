@testable import Accounts

extension StepType: Equatable {
    public static func == (lhs: StepType, rhs: StepType) -> Bool {
        switch (lhs, rhs) {
        case (.text(let lhsText), .text(let rhsText)):
            return lhsText == rhsText
        case (.linkText(let lhsLinkText), .linkText(let rhsLinkText)):
            return lhsLinkText == rhsLinkText
        default:
            return false
        }
    }
}
