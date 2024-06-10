import Accounts

public class MockCancelSubscriptionStepsHelper: CancelSubscriptionStepsHelperProtocol {
    var loadCancellationDataCalled = false
    let data: CancelSubscriptionData
    
    public init(data: CancelSubscriptionData) {
        self.data = data
    }
    
    public func loadCancellationData() -> CancelSubscriptionData {
        loadCancellationDataCalled = true
        return data
    }
}
