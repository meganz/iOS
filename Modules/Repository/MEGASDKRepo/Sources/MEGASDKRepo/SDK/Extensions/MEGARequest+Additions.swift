import MEGASdk

public extension MEGARequest {
    func progress() -> Double {
        Double(transferredBytes) / Double(totalBytes) * 1000
    }
}
