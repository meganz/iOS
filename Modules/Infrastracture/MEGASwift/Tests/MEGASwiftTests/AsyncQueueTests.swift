@testable import MEGASwift
import XCTest

final class AsyncCircularQueueTests: XCTestCase {
    // MARK: Tests without Overflow behaviour
    func testEnqueue_withRequiredCapacity_shouldSucceed() async throws {
        let queue = AsyncCircularQueue<Int>(capacity: 10)
        let result = await queue.enqueue(1)
        XCTAssertTrue(result, "Enqueue operation should succeed.")
        let count = await queue.count
        XCTAssertEqual(count, 1, "Count should be 1 after enqueuing an element.")
    }
    
    func testEnqueue_withRequiredCapacity_shouldFail() async throws {
        let queue = AsyncCircularQueue<Int>(capacity: 10)
        let capacity = await queue.capacity
        for i in 0..<capacity {
            await queue.enqueue(i)
        }
        let result = await queue.enqueue(100)
        XCTAssertFalse(result, "Enqueue operation to a full queue should return false.")
    }
    
    func testDequeue_withEnqueuedItems_shouldSucceed() async throws {
        let queue = AsyncCircularQueue<Int>(capacity: 10)
        await queue.enqueue(1)
        let element = await queue.dequeue()
        XCTAssertEqual(element, 1, "Dequeued element should be equal to the enqueued element.")
        let count = await queue.count
        XCTAssertEqual(count, 0, "Count should be 0 after dequeuing an element.")
    }
    
    func testDequeue_withEmptyQueue_shouldFail() async throws {
        let queue = AsyncCircularQueue<Int>(capacity: 10)
        let element = await queue.dequeue()
        XCTAssertNil(element, "Dequeue operation from an empty queue should return nil.")
    }
    
    func testIsFull_beforeAndAfterEnqueueing_shouldUpdate() async throws {
        let queue = AsyncCircularQueue<Int>(capacity: 10)
        var isFull = await queue.isFull
        XCTAssertFalse(isFull, "Queue should be empty initially.")
        
        let capacity = await queue.capacity
        for i in 0..<capacity {
            await queue.enqueue(i)
        }
        isFull = await queue.isFull
        XCTAssertTrue(isFull, "Queue should be full after enqueuing capacity number of elements.")
        
        await queue.dequeue()
        isFull = await queue.isFull
        XCTAssertFalse(isFull, "Queue should not be full after dequeueing.")
    }
    
    func testIsEmpty_beforeAndAfterEnqueueing_shouldUpdate() async throws {
        let queue = AsyncCircularQueue<Int>(capacity: 10)
        var isEmpty = await queue.isEmpty
        XCTAssertTrue(isEmpty, "Queue should be empty initially.")
        await queue.enqueue(1)
        isEmpty = await queue.isEmpty
        XCTAssertFalse(isEmpty, "Queue should not be empty after enqueuing an element.")
    }
    
    func testPeek_beforeAndAfterEnqueueing_shouldUpdate() async {
        let queue = AsyncCircularQueue<Int>(capacity: 2)
        
        // Queue is empty, so peek should return nil
        var top = await queue.peek()
        XCTAssertNil(top, "peek should be nil when AsyncCircularQueue is empty.")
        
        // Enqueue an element and test peek
        let result = await queue.enqueue(1)
        top = await queue.peek()
        XCTAssertTrue(result, "Enqueue operation should succeed.")
        XCTAssertEqual(top, 1, "Peek element should not change after enqueue operation")
        
        // Enqueue another element, dequeue, and test peek
        await queue.enqueue(2)
        await queue.dequeue()
        top = await queue.peek()
        XCTAssertEqual(top, 2, "Peek element should change after enqueue operation")
    }
    
    // MARK: Tests with Overflow behaviour
    func testEnqueue_withoutCapacityAndAllowingOverflow_shouldDropOldestAndAllowEnqueue() async {
        let queue = AsyncCircularQueue<Int>(capacity: 2, allowEnqueueOverflow: true)
        await queue.enqueue(1)
        await queue.enqueue(2)
        var count = await queue.count
        var top = await queue.peek()
        XCTAssertEqual(count, 2, "Count should be 1 after enqueueing an element.")
        XCTAssertEqual(top, 1, "The oldest element should be equal to the enqueued element.")
        
        await queue.enqueue(3)
        count = await queue.count
        top = await queue.peek()
        XCTAssertEqual(count, 2, "Count should be 2 after enqueueing an element, while allowing overflow at maximum capacity.")
        XCTAssertEqual(top, 2, "The oldest element should be equal to the next oldest enqueued element, while allowing overflow at maximum capacity.")
    }
}
