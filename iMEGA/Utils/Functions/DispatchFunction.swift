import Foundation

// MARK: - Asynchronous on Queue

func async(_ action: @escaping @Sendable () -> Void, on queue: DispatchQueue) {
    queue.async(execute: action)
}

func asyncOnGlobal(_ closure: @escaping @Sendable () -> Void) {
    async(closure, on: .global())
}
