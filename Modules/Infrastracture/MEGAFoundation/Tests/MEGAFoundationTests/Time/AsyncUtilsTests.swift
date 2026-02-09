import Foundation
@testable import MEGAFoundation
import Testing

@Suite("AsyncUtils Tests")
struct AsyncUtilsTests {
    
    // MARK: - Normal Completion Scenarios
    
    @Test("Operation completes before timeout, returns operation result")
    func test_operationCompletesBeforeTimeout() async {
        let result = await AsyncUtils.timeout(5, default: "default") {
            return "success"
        }
        
        #expect(result == "success")
    }
    
    @Test("Operation with delay completes before timeout")
    func test_operationWithDelayCompletesBeforeTimeout() async {
        let result = await AsyncUtils.timeout(2, default: "default") {
            try await Task.sleep(nanoseconds: 100_000_000)
            return "success"
        }
        
        #expect(result == "success")
    }
    
    // MARK: - Timeout Scenarios
    
    @Test("Operation times out, returns default value")
    func test_operationTimesOut() async {
        let result = await AsyncUtils.timeout(0.1, default: "default") {
            try await Task.sleep(nanoseconds: 5_000_000_000)
            return "success"
        }
        
        #expect(result == "default")
    }
    
    @Test("Zero timeout, immediately returns default value")
    func test_zeroTimeout() async {
        let result = await AsyncUtils.timeout(0, default: "default") {
            try await Task.sleep(nanoseconds: 1_000_000_000)
            return "success"
        }
        
        #expect(result == "default")
    }
    
    @Test("Negative timeout, treated as zero")
    func test_negativeTimeout() async {
        let result = await AsyncUtils.timeout(-5, default: "default") {
            try await Task.sleep(nanoseconds: 1_000_000_000)
            return "success"
        }
        
        #expect(result == "default")
    }
    
    // MARK: - Error Scenarios
    
    @Test("Operation throws error, returns default value")
    func test_operationThrowsError() async {
        let result = await AsyncUtils.timeout(5, default: "default") {
            throw NSError(domain: "test", code: 1)
        }
        
        #expect(result == "default")
    }
    
    @Test("Operation throws CancellationError, returns default value")
    func test_operationThrowsCancellationError() async {
        let result = await AsyncUtils.timeout(5, default: "default") {
            throw CancellationError()
        }
        
        #expect(result == "default")
    }
    
    // MARK: - Different Types
    
    @Test("Supports Int type")
    func test_intType() async {
        let result = await AsyncUtils.timeout(5, default: 0) {
            return 42
        }
        
        #expect(result == 42)
    }
    
    @Test("Supports Optional type")
    func test_optionalType() async {
        let result: String? = await AsyncUtils.timeout(5, default: nil) {
            return "value"
        }
        
        #expect(result == "value")
    }
    
    @Test("Supports Array type")
    func test_arrayType() async {
        let result = await AsyncUtils.timeout(5, default: [Int]()) {
            return [1, 2, 3]
        }
        
        #expect(result == [1, 2, 3])
    }
    
    // MARK: - Cancellation Verification
    
    @Test("Task is cancelled on timeout")
    func test_taskIsCancelledOnTimeout() async {
        actor CancellationTracker {
            var wasCancelled = false
            func markCancelled() { wasCancelled = true }
        }
        
        let tracker = CancellationTracker()
        
        let result = await AsyncUtils.timeout(0.1, default: "default") {
            do {
                try await Task.sleep(nanoseconds: 5_000_000_000)
                return "success"
            } catch is CancellationError {
                await tracker.markCancelled()
                throw CancellationError()
            }
        }
        
        #expect(result == "default")
        #expect(await tracker.wasCancelled == true)
    }
}

@Suite("Task.valueOrNil Tests")
struct TaskValueOrNilTests {
    
    @Test("Task succeeds, returns value")
    func test_taskSucceeds() async {
        let task = Task<String, any Error> {
            return "success"
        }
        
        let result = await task.valueOrNil
        #expect(result == "success")
    }
    
    @Test("Task throws error, returns nil")
    func test_taskThrows() async {
        let task = Task<String, any Error> {
            throw NSError(domain: "test", code: 1)
        }
        
        let result = await task.valueOrNil
        #expect(result == nil)
    }
    
    @Test("Task is cancelled, returns nil")
    func test_taskCancelled() async {
        let task = Task<String, any Error> {
            try await Task.sleep(nanoseconds: 5_000_000_000)
            return "success"
        }
        
        task.cancel()
        let result = await task.valueOrNil
        #expect(result == nil)
    }
}
