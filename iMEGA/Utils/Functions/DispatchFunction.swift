import Foundation

// MARK: - Asynchronous on Queue

func async(_ action: @escaping () -> Void, on queue: DispatchQueue) {
    queue.async(execute: action)
}

func async(on queue: DispatchQueue, _ action: @escaping () -> Void) {
    queue.async(execute: action)
}

func asyncOnMain(_ closure: @escaping () -> Void) {
    async(closure, on: .main)
}

func asyncOnGlobal(_ closure: @escaping () -> Void) {
    async(closure, on: .global())
}

// MARK: - Weakify Reference Objects

func weakify<A: AnyObject>(_ toBeWeakified: A?, weakifiedSelfCode: @escaping (A) -> Void) -> () -> Void {
    return { [weak toBeWeakified] in
        guard let toBeWeakified = toBeWeakified else { return }
        weakifiedSelfCode(toBeWeakified)
    }
}
