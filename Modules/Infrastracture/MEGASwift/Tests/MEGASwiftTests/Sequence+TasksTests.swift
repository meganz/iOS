import Foundation
import MEGASwift
import Testing

struct SequenceTasksTests {
    /// This is a helper class to be used in test functions. It will track all tasks executed, maximum number of concurrent executing tasks.
    /// These tracked information then is used in assertion (#expect marco).
    private final class ConcurrentTasksTracker: @unchecked Sendable {
        // number of tasks currently executing.
        private var executingTasksCount = 0
        // all the tasks that are executed.
        private(set) var executedTasks: [Int] = []
        // maximum of concurrent executing tasks of all time
        private(set) var maxConcurrentTasksCount = 0
        private let lock = NSLock()
        
        func execute(item: Int) async {
            lock.withLock {
                executedTasks.append(item)
                executingTasksCount += 1
                maxConcurrentTasksCount = max(maxConcurrentTasksCount, executingTasksCount)
            }
            
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            
            lock.withLock {
                executingTasksCount -= 1
            }
        }
    }
    
    private let items = (1...10).map { $0 }
    private let concurrentTasksTracker = ConcurrentTasksTracker()
    
    @Test
    func test_numberOfConcurrentTasks_shouldNotExceed_maxConcurrentTasks() async {
        await items.taskGroup(maxConcurrentTasks: 3) { item in
            await concurrentTasksTracker.execute(item: item)
        }
        
        #expect(Set(concurrentTasksTracker.executedTasks) == Set(items)) // All tasks (items) should be executed. Set is used since order is not guaranteed
        #expect(concurrentTasksTracker.maxConcurrentTasksCount <= 3) // The max concurrent executing tasks should not exceed 3 (`maxConcurrentTasks` param)
    }
    
    @Test
    func test_whenCancelled_shouldStopAddingMoreTasks() async {
        let task = Task {
            await items.taskGroup(maxConcurrentTasks: 3) { item in
                await concurrentTasksTracker.execute(item: item)
            }
        }
        
        task.cancel()
        
        _ = await task.value
        
        #expect(concurrentTasksTracker.executedTasks.count < items.count)
    }
}
