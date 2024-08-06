import MEGAL10n

public enum CancellationSurveyReason: Int, CaseIterable {
    case one, two, three, four, five, six, seven, eight, nine, ten
    
    var id: Int { self.rawValue }
    
    var title: String {
        switch self {
        case .one: Strings.Localizable.Accounts.CancelSubscriptionSurvey.Reason.one
        case .two: Strings.Localizable.Accounts.CancelSubscriptionSurvey.Reason.two
        case .three: Strings.Localizable.Accounts.CancelSubscriptionSurvey.Reason.three
        case .four: Strings.Localizable.Accounts.CancelSubscriptionSurvey.Reason.four
        case .five: Strings.Localizable.Accounts.CancelSubscriptionSurvey.Reason.five
        case .six: Strings.Localizable.Accounts.CancelSubscriptionSurvey.Reason.six
        case .seven: Strings.Localizable.Accounts.CancelSubscriptionSurvey.Reason.seven
        case .eight: Strings.Localizable.Accounts.CancelSubscriptionSurvey.Reason.eight
        case .nine: Strings.Localizable.Accounts.CancelSubscriptionSurvey.Reason.nine
        case .ten: Strings.Localizable.Accounts.CancelSubscriptionSurvey.Reason.ten
        }
    }
    
    var isOtherReason: Bool {
        self == .eight
    }
    
    static var otherReason: CancellationSurveyReason { .eight }
}
