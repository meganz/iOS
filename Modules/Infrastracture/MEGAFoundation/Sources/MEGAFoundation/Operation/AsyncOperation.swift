import Foundation
import MEGASwift

/// This `AsyncOperation` is the Swift version of `MEGAOperation`
/// We still need to keep `MEGAOperation` because there are some Objective-C based classes
/// such `CameraUploadOperation`, `ImageExportOperation`, `MEGABackgroundTaskOperation` etc.
/// The reason is Objective-C classes can not inherit Swift class
/// We can remove `MEGAOperation` in the future when we migrate all mentioned Objective-C classes to Swift.
open class AsyncOperation: Operation, @unchecked Sendable {
    @Atomic private var _executing = false {
        willSet {
            willChangeValue(forKey: "isExecuting")
        }
        didSet {
            didChangeValue(forKey: "isExecuting")
        }
    }
    @Atomic private var _finished = false {
        willSet {
            willChangeValue(forKey: "isFinished")
        }
        didSet {
            didChangeValue(forKey: "isFinished")
        }
    }
    
    public override var isExecuting: Bool {
        return _executing
    }
    
    public override var isFinished: Bool {
        return _finished
    }
    
    public override var isAsynchronous: Bool {
        return true
    }
    
    open override func start() {
        if isFinished {
            return
        }
        
        if isCancelled {
            finishOperation()
            return
        }
        
        startExecuting()
    }
    
    public func startExecuting() {
        $_executing.mutate { $0 = true }
    }
    
    public func finishOperation() {
        if isFinished {
            return
        }
        
        $_executing.mutate { $0 = false }
        $_finished.mutate { $0 = true }
    }
    
    public func cancelOperation() {
        cancel()
        finishOperation()
    }
}
