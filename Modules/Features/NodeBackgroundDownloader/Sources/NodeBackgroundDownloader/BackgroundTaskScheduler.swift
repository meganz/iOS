@preconcurrency import BackgroundTasks
import MEGAAppSDKRepo
import MEGADomain
import MEGAL10n
import MEGASwift

enum BackgroundTaskSchedulerError: Error {
    case registerFailed
    case submitFailed(any Error)
}

@available(iOS 26.0, *)
protocol BackgroundTaskSchedulerProtocol: Sendable {
    typealias LaunchHandler = @Sendable (BGContinuedProcessingTask) async -> Void
    
    func scheduleTask(
        launchHandler: @escaping LaunchHandler
    ) throws
}

@available(iOS 26.0, *)
struct BackgroundTaskScheduler: BackgroundTaskSchedulerProtocol {
    private let taskScheduler = BGTaskScheduler.shared
    
    func scheduleTask(
        launchHandler: @escaping LaunchHandler
    ) throws {
        let taskIdentifier = createTaskIdentifier()
        let registered = taskScheduler.register(forTaskWithIdentifier: taskIdentifier, using: nil) { task in
            guard let continuedProcessingTask = task as? BGContinuedProcessingTask else {
                return
            }
            
            let task = Task {
                await launchHandler(continuedProcessingTask)
            }
            
            continuedProcessingTask.expirationHandler = {
                task.cancel()
            }
        }
        
        MEGALogDebug("[BGTask] \(taskIdentifier) registered \(registered)")
        if registered {
            try submitRequest(withTaskIdentifier: taskIdentifier)
        } else {
            throw BackgroundTaskSchedulerError.registerFailed
        }
    }
    
    private func createTaskIdentifier() -> String {
        let bundleIdentifier = Bundle.main.bundleIdentifier ?? "mega.ios"
        let taskId = UUID().uuidString
        let components: [String] = [bundleIdentifier, "transfers.BGContinuedProcessingTask", taskId]
        return components.joined(separator: ".")
    }
    
    private func submitRequest(withTaskIdentifier identifier: String) throws {
        let request = BGContinuedProcessingTaskRequest(
            identifier: identifier,
            title: Strings.Localizable.downloading,
            subtitle: Strings.Localizable.downloading
        )
        request.strategy = .fail
        
        do {
            try taskScheduler.submit(request)
            MEGALogDebug("[BGTask] \(identifier) submit request")
        } catch {
            MEGALogError("[BGTask] \(identifier) failed to submit request: \(error)")
            throw BackgroundTaskSchedulerError.submitFailed(error)
        }
    }
}
