/// Helper to check whether upgrade encouragement was presented during the current app launch
@MainActor protocol UpgradeEncouragementShowTimeTracking: AnyObject {
    var alreadyPresented: Bool { get set }
}

final class UpgradeEncouragementShowTimeTracker: UpgradeEncouragementShowTimeTracking {
    static var alreadyPresented = false
    var alreadyPresented: Bool {
        get {
            Self.alreadyPresented
        }
        set {
            Self.alreadyPresented = newValue
        }
    }
}
