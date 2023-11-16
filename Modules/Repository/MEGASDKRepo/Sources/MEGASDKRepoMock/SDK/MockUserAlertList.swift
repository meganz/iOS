import MEGASdk

public final class MockUserAlertList: MEGAUserAlertList {
    
    public private(set) var alerts: [MEGAUserAlert]
    
    public init(
        alerts: [MEGAUserAlert] = []
    ) {
        self.alerts = alerts
    }
    
    public override var size: Int { alerts.count }
    
    public override func usertAlert(at index: Int) -> MEGAUserAlert? {
        alerts[index]
    }
}
