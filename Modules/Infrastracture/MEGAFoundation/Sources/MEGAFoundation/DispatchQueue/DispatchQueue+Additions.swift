import Foundation

public extension DispatchQueue {
    func asyncPerform(work: @escaping @Sendable () -> Void) async {
        await withCheckedContinuation { continuation in
            self.async {
                work()
                continuation.resume()
            }
        }
    }
}
