
public extension Result where Success == Void {
    static var success: Result {
        return .success(())
    }
}
