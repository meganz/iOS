import MEGAL10n

struct CancellationSurveyReason: Hashable {
    enum ID: Int, CaseIterable {
        case one, two, three, four, five, six, seven, eight, nine, ten
    }
    
    let id: ID
    let title: String
    let followUpReasons: [CancellationSurveyFollowUpReason]
    
    init(
        id: ID,
        title: String,
        followUpReasons: [CancellationSurveyFollowUpReason] = []
    ) {
        self.id = id
        self.title = title
        self.followUpReasons = followUpReasons
    }
    
    static func makeList() -> [CancellationSurveyReason] {
        var list = [
            CancellationSurveyReason(
                id: .one,
                title: Strings.Localizable.Accounts.CancelSubscriptionSurvey.Reason.one,
                followUpReasons: [
                    CancellationSurveyFollowUpReason(id: .a, mainReasonID: .one, title: Strings.Localizable.Accounts.CancelSubscriptionSurvey.Reason.One.a),
                    CancellationSurveyFollowUpReason(id: .b, mainReasonID: .one, title: Strings.Localizable.Accounts.CancelSubscriptionSurvey.Reason.One.b),
                    CancellationSurveyFollowUpReason(id: .c, mainReasonID: .one, title: Strings.Localizable.Accounts.CancelSubscriptionSurvey.Reason.One.c)
                ].shuffled()
            ),
            CancellationSurveyReason(id: .two, title: Strings.Localizable.Accounts.CancelSubscriptionSurvey.Reason.two),
            CancellationSurveyReason(id: .three, title: Strings.Localizable.Accounts.CancelSubscriptionSurvey.Reason.three),
            CancellationSurveyReason(id: .four, title: Strings.Localizable.Accounts.CancelSubscriptionSurvey.Reason.four),
            CancellationSurveyReason(id: .five, title: Strings.Localizable.Accounts.CancelSubscriptionSurvey.Reason.five),
            CancellationSurveyReason(id: .six, title: Strings.Localizable.Accounts.CancelSubscriptionSurvey.Reason.six),
            CancellationSurveyReason(id: .seven, title: Strings.Localizable.Accounts.CancelSubscriptionSurvey.Reason.seven),
            CancellationSurveyReason(id: .nine, title: Strings.Localizable.Accounts.CancelSubscriptionSurvey.Reason.nine),
            CancellationSurveyReason(id: .ten, title: Strings.Localizable.Accounts.CancelSubscriptionSurvey.Reason.ten)
        ].shuffled()
        
        list.append(
            CancellationSurveyReason(id: .eight, title: Strings.Localizable.Accounts.CancelSubscriptionSurvey.Reason.eight)
        )
        
        return list
    }

    static var otherReasonID: ID {
        .eight
    }
    
    var isOtherReason: Bool {
        id == CancellationSurveyReason.otherReasonID
    }
}
