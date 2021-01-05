import Foundation

final class Debouncer {

    private var delay: TimeInterval

    private var dispatchQueue: DispatchQueue

    private var dispatchWork: DispatchWorkItem?

    init(delay: TimeInterval, dispatchQueue: DispatchQueue = .main) {
        self.delay = delay
        self.dispatchQueue = dispatchQueue
    }

    fileprivate func execute(_ action: @escaping () -> Void) {
        let dispatchWork = DispatchWorkItem {
            action()
        }
        self.dispatchWork = dispatchWork
        dispatchQueue.asyncAfter(deadline: .now() + delay, execute: dispatchWork)
    }

    func start(action: @escaping () -> Void) {
        guard let scheduleWork = dispatchWork else {
            execute(action)
            return
        }

        if !scheduleWork.isCancelled {
            scheduleWork.cancel()
        }
        execute(action)
    }

    func cancel() {
        dispatchWork?.cancel()
    }
}
