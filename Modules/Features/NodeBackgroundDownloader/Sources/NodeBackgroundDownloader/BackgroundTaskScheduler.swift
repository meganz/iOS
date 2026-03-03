@preconcurrency import BackgroundTasks
import MEGAAppPresentation
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
    private let bgTaskAnalytics: any BGTaskAnalyticsUseCaseProtocol

    init(bgTaskAnalytics: some BGTaskAnalyticsUseCaseProtocol) {
        self.bgTaskAnalytics = bgTaskAnalytics
    }

    init() {
        self.init(bgTaskAnalytics: BGTaskAnalyticsUseCase(tracker: DIContainer.tracker))
    }

    func scheduleTask(
        launchHandler: @escaping LaunchHandler
    ) throws {
        let taskIdentifier = createTaskIdentifier()
        let submitTime = Date()
        let bgTaskAnalytics = bgTaskAnalytics

        let registered = taskScheduler.register(forTaskWithIdentifier: taskIdentifier, using: nil) { task in
            guard let continuedProcessingTask = task as? BGContinuedProcessingTask else {
                return
            }

            let delaySeconds = Date().timeIntervalSince(submitTime)
            bgTaskAnalytics.trackSchedulingDelay(delaySeconds: delaySeconds)

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
            bgTaskAnalytics.trackScheduleFailure(reason: .registerFailed)
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
            bgTaskAnalytics.trackScheduleFailure(reason: .submitFailed)
            throw BackgroundTaskSchedulerError.submitFailed(error)
        }
    }
}
