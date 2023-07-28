import MEGADomain
import MEGASdk

extension MEGAHandleList {
    public func toHandleEntityArray() -> [HandleEntity]? {
        return (0..<size).map { megaHandle(at: $0) }
    }
}
