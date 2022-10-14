import MEGADomain

extension MEGAHandleList {
    func toHandleEntityArray() -> [HandleEntity]? {
        return (0..<size).map { megaHandle(at: $0) }
    }
}
