import Foundation

public enum AsyncUtils {
    public static func timeout<T: Sendable>(
        _ seconds: TimeInterval,
        default value: T,
        _ operation: @escaping @Sendable () async throws -> T
    ) async -> T {
        let task = Task { try await operation() }
        let timeoutTask = Task {
            let sec = seconds < 0 ? 0 : seconds
            try await Task.sleep(nanoseconds: UInt64(sec * 1_000_000_000))
            task.cancel()
        }
         
        let result = await task.valueOrNil
        timeoutTask.cancel()
        return result ?? value
    }
}
 
extension Task where Failure == any Error {
    var valueOrNil: Success? {
        get async {
            do {
                return try await self.value
            } catch { return nil }
        }
    }
}
