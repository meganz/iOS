
import Foundation

final class TimeoutTask<Success> {
    private let duration: TimeInterval
    private let operation: @Sendable () async throws -> Success
    private var continuation: CheckedContinuation<Success, Error>?
    
    var value: Success {
        get async throws {
            try await withCheckedThrowingContinuation { continuation in
                self.continuation = continuation
                
                Task {
                    try await Task.sleep(seconds: duration)
                    self.continuation?.resume(throwing: TimeoutError())
                    self.continuation = nil
                }
                
                Task {
                    let result = try await operation()
                    self.continuation?.resume(returning: result)
                    self.continuation = nil
                }
            }
        }
    }
    
    init(duration: TimeInterval,
         operation: @escaping @Sendable () async throws -> Success) {
        self.duration = duration
        self.operation = operation
    }
    
    func cancel() {
        continuation?.resume(throwing: CancellationError())
        continuation = nil
    }
}

extension TimeoutTask {
    struct TimeoutError: LocalizedError {
        var errorDescription: String? {
            return "The operation timed out."
        }
    }
}

extension Task where Success == Never, Failure == Never {
    static func sleep(seconds: Double) async throws {
        let duration = UInt64(seconds * 1_000_000_000)
        try await Task.sleep(nanoseconds: duration)
    }
}
