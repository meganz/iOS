import MEGASdk

public extension MEGASdk {
    @objc static func currentUserHandle() -> NSNumber? {
        CurrentUserSource.shared.currentUserHandle.map {
            NSNumber(value: $0)
        }
    }
}
