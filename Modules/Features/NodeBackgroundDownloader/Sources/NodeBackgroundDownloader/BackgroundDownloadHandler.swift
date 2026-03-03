@preconcurrency import BackgroundTasks
@preconcurrency import FirebaseCrashlytics
import MEGAAppPresentation
import MEGAAppSDKRepo
import MEGADomain
import MEGAL10n
import MEGARepo
import MEGASwift
import UIKit

@available(iOS 26.0, *)
public protocol BackgroundDownloadHandlerProtocol: Sendable {
    func handleBackgroundDownload(for node: NodeEntity) async
}

@available(iOS 26.0, *)
public actor BackgroundDownloadHandler: BackgroundDownloadHandlerProtocol {
    private let taskScheduler: any BackgroundTaskSchedulerProtocol
    private let taskExpirationNotifier: any BackgroundTaskExpirationNotifierProtocol
    private var taskProgressMonitor: (any BackgroundTaskProgressMonitorProtocol)?
    private let crashlytics: Crashlytics
    private let bgTaskAnalytics: any BGTaskAnalyticsUseCaseProtocol
    private let appStateProvider: any ApplicationStateProviderProtocol
    private var taskStartTime: Date?

    public static let shared = BackgroundDownloadHandler()

    init(
        taskScheduler: some BackgroundTaskSchedulerProtocol,
        taskExpirationNotifier: some BackgroundTaskExpirationNotifierProtocol,
        taskProgressMonitor: some BackgroundTaskProgressMonitorProtocol,
        crashlytics: Crashlytics = Crashlytics.crashlytics(),
        bgTaskAnalytics: some BGTaskAnalyticsUseCaseProtocol,
        appStateProvider: some ApplicationStateProviderProtocol = ApplicationStateProvider()
    ) {
        self.taskScheduler = taskScheduler
        self.taskExpirationNotifier = taskExpirationNotifier
        self.taskProgressMonitor = taskProgressMonitor
        self.crashlytics = crashlytics
        self.bgTaskAnalytics = bgTaskAnalytics
        self.appStateProvider = appStateProvider
    }

    init() {
        let bgTaskAnalytics = BGTaskAnalyticsUseCase(tracker: DIContainer.tracker)

        let taskScheduler = BackgroundTaskScheduler(bgTaskAnalytics: bgTaskAnalytics)

        let taskExpirationNotifier = BackgroundTaskExpirationNotifier(
            localNotificationRepository: LocalNotificationRepository()
        )

        let nodeDownloadUpdatesUseCase = NodeDownloadUpdatesUseCase(repo: NodeTransferRepository.newRepo)
        let taskProgressMonitor = BackgroundTaskProgressMonitor(nodeDownloadUpdates: nodeDownloadUpdatesUseCase)

        self.init(
            taskScheduler: taskScheduler,
            taskExpirationNotifier: taskExpirationNotifier,
            taskProgressMonitor: taskProgressMonitor,
            bgTaskAnalytics: bgTaskAnalytics
        )
    }

    public func handleBackgroundDownload(for node: NodeEntity) {
        do {
            if let taskProgressMonitor, !taskProgressMonitor.allCompleted {
                taskProgressMonitor.start(node: node)
                return
            }
            
            let nodeDownloadUpdatesUseCase = NodeDownloadUpdatesUseCase(repo: NodeTransferRepository.newRepo)
            let taskProgressMonitor = BackgroundTaskProgressMonitor(nodeDownloadUpdates: nodeDownloadUpdatesUseCase)
            self.taskProgressMonitor = taskProgressMonitor
            
            taskProgressMonitor.start(node: node)

            taskStartTime = Date()
            let startTime = taskStartTime
            let bgTaskAnalytics = bgTaskAnalytics
            let appStateProvider = appStateProvider

            try taskScheduler.scheduleTask { [taskProgressMonitor, taskExpirationNotifier] task in
                await withTaskCancellationHandler {
                    task.progress.totalUnitCount = 0
                    task.progress.completedUnitCount = 0
                    await taskProgressMonitor.start { total in
                        task.progress.totalUnitCount = total
                    } onCompleted: { completed in
                        task.progress.completedUnitCount = completed
                        let formattedText = Strings.Localizable.Notification.Transfer.Download.subtitle(taskProgressMonitor.completedDownloads)
                        let subtitle = formattedText.replacing("[A]", with: String(format: "%d", taskProgressMonitor.totalDownloads))
                        task.updateTitle(
                            Strings.Localizable.Notification.Transfer.Download.title,
                            subtitle: subtitle)
                        MEGALogDebug("[BGTask] \(task.identifier) progress completed =  \(task.progress.completedUnitCount) total = \(task.progress.totalUnitCount)")
                    }

                    let success = task.progress.isFinished
                    task.setTaskCompleted(success: success)
                    MEGALogDebug("[BGTask] \(task.identifier) completed with success: \(success)")

                    if let startTime, success {
                        let duration = Date().timeIntervalSince(startTime)
                        bgTaskAnalytics.trackTaskCompleted(durationSeconds: duration)
                    }
                } onCancel: {
                    taskProgressMonitor.stop()
                    taskExpirationNotifier.notify(for: task.identifier, title: task.title)

                    if let startTime {
                        let duration = Date().timeIntervalSince(startTime)
                        let total = task.progress.totalUnitCount
                        let completed = task.progress.completedUnitCount
                        let completionPercentage = total > 0 ? Double(completed) / Double(total) * 100.0 : 0.0

                        Task { @MainActor in
                            let appState: BGTaskAppState = appStateProvider.applicationState == .active ? .active : .background
                            bgTaskAnalytics.trackTaskExpired(
                                durationSeconds: duration,
                                completionPercentage: completionPercentage,
                                appState: appState
                            )
                        }
                    }
                }
            }
        } catch {
            crashlytics.record(error: error)
            MEGALogError("[BGTask] Failed to schedule background task for node: \(node.base64Handle) with error: \(error)")
        }
    }
}
