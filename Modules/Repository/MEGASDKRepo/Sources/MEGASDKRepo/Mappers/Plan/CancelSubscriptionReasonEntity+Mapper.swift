import MEGADomain
import MEGASdk

private extension CancelSubscriptionReasonEntity {
    func toCancelSubscriptionReason() -> MEGACancelSubscriptionReason {
        MEGACancelSubscriptionReason.create(text, position: position)
    }
}

extension [CancelSubscriptionReasonEntity]? {
    func toMEGACancelSubscriptionReasonList() -> MEGACancelSubscriptionReasonList? {
        guard let self else { return nil }
        
        let list = MEGACancelSubscriptionReasonList.create()
        self.forEach { list.add($0.toCancelSubscriptionReason()) }
        return list
    }
}
