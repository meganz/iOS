import Foundation
import UIKit

/// Collects Camera Upload telemetry: run start and end, failures and given-up files grouped by kind, and heat
/// snapshots during a run. See the Confluence page "Camera Upload — Telemetry Plan (Batch 1)".
///
/// Every entry point returns at once and handles the call on a serial queue, so the order of events is kept and no
/// caller waits, including callers inside a Core Data `performBlockAndWait`.
@objc final class CameraUploadTelemetry: NSObject, @unchecked Sendable {
    @objc static let shared = CameraUploadTelemetry(sink: CameraUploadTelemetryCompositeSink(sinks: defaultSinks))

    /// The local file, exported from About, is kept only in development and QA builds.
    private static var defaultSinks: [any CameraUploadTelemetrySink] {
        #if DEBUG || QA_CONFIG
        return [CameraUploadTelemetryFileSink.shared, CameraUploadTelemetryFirebaseSink()]
        #else
        return [CameraUploadTelemetryFirebaseSink()]
        #endif
    }

    private enum Constants {
        static let tallySendingInterval: TimeInterval = 15 * 60
        static let triggerLifetime: TimeInterval = 10 * 60
        static let foregroundTriggerWindow: TimeInterval = 5
        static let persistDelay: TimeInterval = 3
        /// While a run is going, the queue notes every few seconds that the process is still running. A longer gap
        /// in the background means iOS suspended the app.
        static let heartbeatInterval: TimeInterval = 5
        static let suspensionGap: TimeInterval = 30
        /// When several things nudged Camera Upload before a run started, the first of these names the run.
        static let triggerPriority = [
            "settings_changed", "bg_refresh", "bg_processing", "bg_upload_events", "app_launch", "resumed", "network_back",
            "library_changed", "foreground", "concurrency_changed", "nodes_ready"
        ]
    }

    private let sink: any CameraUploadTelemetrySink
    private let pipeline = CameraUploadPipelineMonitor()
    private let queue = DispatchQueue(label: "nz.mega.cameraUpload.telemetry", qos: .utility)
    private let stateStore = CameraUploadTelemetryStateStore()
    private let userProperties: CameraUploadTelemetryUserProperties

    // MARK: - State, accessed only on `queue`

    private var state = CameraUploadTelemetryState()
    private var hasStarted = false
    /// Triggers noted since the last run started or the last check found nothing to queue.
    private var pendingTriggers: [String: Date] = [:]
    /// Assumed until the app is seen in the foreground: in a scene-based app, `applicationState` is `.background` during
    /// launch also when the user opens the app.
    private var isInBackground = true
    private var becameActiveAt: Date?
    private var isCharging = false
    private var isProgressViewVisible = false
    private var thermalState = CameraUploadDeviceSnapshot.thermalState
    private var maxPhotoConcurrency = 0
    private var maxVideoConcurrency = 0
    private var persistWorkItem: DispatchWorkItem?
    private var tallySendingWorkItem: DispatchWorkItem?
    private var heartbeat: (any DispatchSourceTimer)?
    private var isNodeTreeCurrent = false
    private var hasBeenInForeground = false
    /// Whether this process ran in the background, woken by iOS or after the user left the app.
    private var hasRunInBackground = false
    private var wakesInProcess = 0
    /// Set once in `start()` on the main thread.
    private var notificationObservers: [any NSObjectProtocol] = []

    init(sink: some CameraUploadTelemetrySink) {
        self.sink = sink
        userProperties = CameraUploadTelemetryUserProperties(sink: sink)
        super.init()
    }

    // MARK: - Lifecycle

    /// Call once per launch, on the main thread. Sends what a run ended by iOS left behind in the previous process.
    @objc func start() {
        queue.async { [self] in
            guard !hasStarted else { return }
            hasStarted = true
            let date = Date()
            loadState()
            if let run = state.run {
                let reason: CameraUploadRunEndReason = run.lastActivityInBackground == true ? .endedInBackground : .killed
                endRun(reason, at: run.lastActivityAt, backlogEnd: run.lastKnownBacklog)
            }
            if let wake = state.wake {
                endWake(
                    wake.areUploadEventsDelivered ? .workDone : .suspended,
                    at: wake.lastActivityAt,
                    deviceNow: wake.lastDeviceNow,
                    backlogEnd: wake.lastKnownBacklog
                )
            }
            sendTallies()
            pendingTriggers["app_launch"] = date
            userProperties.refresh()
        }
        observeSystemNotifications()
        if Thread.isMainThread {
            MainActor.assumeIsolated {
                refreshMainThreadState(isInBackground: UIApplication.shared.applicationState == .background)
            }
        } else {
            DispatchQueue.main.async { [self] in
                MainActor.assumeIsolated {
                    refreshMainThreadState(isInBackground: UIApplication.shared.applicationState == .background)
                }
            }
        }
    }

    /// The app is about to terminate while it may be in a run, e.g. swiped away while still running in the background.
    /// Blocks until the run end is written.
    @objc func appWillTerminate() {
        queue.sync {
            endRun(isInBackground ? .endedInBackground : .killed, at: Date())
        }
        sink.waitUntilWritten()
    }

    /// Background time ran out, so iOS may suspend the app at any moment. The run is not ended here: the app often
    /// keeps running for a while, and the suspension itself is found by the gap it leaves. Returns at once, as the
    /// caller is an expiration handler: the state is already saved in the background, and the wake-up ends with the
    /// backlog last counted.
    @objc func backgroundTimeWillExpire() {
        let date = Date()
        queue.async { [self] in
            if let wake = state.wake {
                endWake(.timeExpired, at: date, backlogEnd: wake.lastKnownBacklog)
            }
            guard var run = state.run, run.backgroundTimeExpiredAt == nil else { return }
            run.backgroundTimeExpiredAt = date
            run.lastActivityAt = date
            run.lastActivityInBackground = true
            state.run = run
            sendTallies()
            persistNow()
        }
    }

    // MARK: - Run boundaries

    /// Something made Camera Upload look for files to queue.
    @objc func noteTrigger(_ trigger: CameraUploadRunTrigger) {
        let date = Date()
        queue.async { [self] in
            var name = trigger.name
            if trigger == .concurrencyChanged, let becameActiveAt,
               date.timeIntervalSince(becameActiveAt) < Constants.foregroundTriggerWindow {
                name = "foreground"
            }
            pendingTriggers[name] = date
            if trigger == .settingsChanged {
                userProperties.refresh()
            }
        }
    }

    /// Files were taken from the queue into the pipeline. Starts a run if none is going.
    @objc func didQueueUpRecords() {
        let date = Date()
        perform { [self] in
            guard state.run == nil else { return }
            startRun(at: date)
        }
    }

    /// Nothing is left to queue and nothing is being prepared.
    @objc func didFinishQueueing() {
        let date = Date()
        perform { [self] in
            if state.run == nil {
                // A check that found nothing to queue: what nudged it does not carry over to a later run.
                pendingTriggers = [:]
            }
            endRun(.queueEmpty, at: date)
        }
    }

    @objc func didPause(_ reason: CameraUploadPauseReason) {
        let date = Date()
        perform { [self] in
            endRun(reason.endReason, at: date)
        }
    }

    @objc func didDisable() {
        let date = Date()
        perform { [self] in
            endRun(.disabled, at: date)
            sendTallies()
            userProperties.refresh()
        }
    }

    @objc func didLogOut() {
        let date = Date()
        perform { [self] in
            endRun(.loggedOut, at: date)
            sendTallies()
            isNodeTreeCurrent = false
        }
    }

    // MARK: - Background wake-ups

    /// iOS woke the app in the background. Ignored if a wake-up is already going or the app is in the foreground.
    @objc func backgroundWakeDidStart(_ type: CameraUploadWakeType) {
        let date = Date()
        perform { [self] in
            startWake(type, at: date)
        }
    }

    /// The background refresh or processing task was completed before its time ran out.
    @objc func backgroundTaskDidFinish() {
        let date = Date()
        perform { [self] in
            let taskTypes = [CameraUploadWakeType.backgroundRefresh.name, CameraUploadWakeType.backgroundProcessing.name]
            guard let type = state.wake?.type, taskTypes.contains(type) else { return }
            endWake(.workDone, at: date)
        }
    }

    /// iOS delivered all events of a background upload session. The wake-up goes on while the finished uploads are
    /// created in the cloud, and ends when the app is suspended.
    @objc func backgroundUploadEventsDidFinish() {
        perform { [self] in
            updateWake { $0.areUploadEventsDelivered = true }
        }
    }

    /// The cloud file tree is loaded, so Camera Upload can queue files.
    @objc func nodesDidBecomeCurrent() {
        let date = Date()
        perform { [self] in
            isNodeTreeCurrent = true
            if state.wake?.readyAt == nil {
                updateWake { $0.readyAt = date }
            }
        }
    }

    // MARK: - Context

    @objc func networkReachabilityChanged(_ isReachable: Bool) {
        perform { [self] in
            guard !isReachable else { return }
            updateRun { $0.wentOffline = true }
        }
    }

    @objc(setMaxConcurrencyForPhotos:videos:)
    func setMaxConcurrency(photos: Int, videos: Int) {
        queue.async { [self] in
            maxPhotoConcurrency = photos
            maxVideoConcurrency = videos
        }
    }

    @objc func setProgressViewVisible(_ isVisible: Bool) {
        queue.async { [self] in
            isProgressViewVisible = isVisible
        }
    }

    // MARK: - Pipeline

    @objc(operation:didEnterStage:isVideo:)
    func operation(_ operation: AnyObject, didEnter stage: CameraUploadPipelineStage, isVideo: Bool) {
        pipeline.setStage(stage, for: operation, isVideo: isVideo)
    }

    @objc func operationDidFinish(_ operation: AnyObject) {
        pipeline.remove(operation)
    }

    // MARK: - File outcomes

    @objc(fileHandedOverIsVideo:)
    func fileHandedOver(isVideo: Bool) {
        perform { [self] in
            updateRun {
                $0.handedOver += 1
                if isVideo { $0.videosHandedOver += 1 }
            }
            updateWake { $0.handedOver += 1 }
            updatePeriod { $0.handedOver += 1 }
        }
    }

    @objc(fileUploadedIsVideo:)
    func fileUploaded(isVideo: Bool) {
        perform { [self] in
            updateRun {
                $0.uploaded += 1
                if isVideo { $0.videosUploaded += 1 }
            }
            updateWake { $0.uploaded += 1 }
            updatePeriod { $0.uploaded += 1 }
        }
    }

    @objc func fileFoundInCloud() {
        perform { [self] in
            updateRun { $0.alreadyInCloud += 1 }
        }
    }

    @objc func filePutAside(_ reason: CameraUploadPutAsideReason) {
        perform { [self] in
            updateRun { $0.putAside += 1 }
        }
    }

    /// A file failed and was marked to be tried again. The counts are the file's failures including this one.
    @objc(fileFailedAtStep:error:isVideo:failuresSinceLaunch:failuresSinceLogin:)
    func fileFailed(
        at step: CameraUploadTelemetryStep,
        error: (any Error)?,
        isVideo: Bool,
        failuresSinceLaunch: Int,
        failuresSinceLogin: Int
    ) {
        let date = Date()
        let nsError = error.map { $0 as NSError }
        perform { [self] in
            recordFailure(
                step: step,
                error: nsError,
                isVideo: isVideo,
                failuresSinceLaunch: failuresSinceLaunch,
                failuresSinceLogin: failuresSinceLogin,
                at: date
            )
        }
    }

    // MARK: - Run handling

    /// Runs `work` on the queue, after ending the run if iOS suspended the app since its last activity.
    private func perform(_ work: @escaping @Sendable () -> Void) {
        queue.async { [self] in
            let now = Date()
            endRunIfSuspended(now: now)
            endWakeIfSuspended(now: now)
            work()
        }
    }

    private func startRun(at date: Date) {
        let trigger = Constants.triggerPriority.first {
            guard let notedAt = pendingTriggers[$0] else { return false }
            return date.timeIntervalSince(notedAt) < Constants.triggerLifetime
        } ?? "other"
        pendingTriggers = [:]
        let mediaTypes = CameraUploadManager.enabledMediaTypes.map(\.intValue)
        let backlog = backlogCount(mediaTypes: mediaTypes)
        var run = CameraUploadRunState(
            id: String(UUID().uuidString.prefix(8)).lowercased(),
            trigger: trigger,
            appState: appStateName,
            startedAt: date,
            backlogStart: backlog,
            thermalState: thermalState
        )
        run.mediaTypes = mediaTypes
        run.lastActivityInBackground = isInBackground
        run.lastKnownBacklog = backlog
        state.run = run

        var parameters = run.group
        parameters.merge(deviceNow(includingThermalState: true)) { $1 }
        parameters["backlog_start"] = .int(backlog)
        sink.logEvent("cu_run_start", parameters: parameters)

        startHeartbeat()
        persistNow()
    }

    /// - Parameter backlogEnd: The backlog when the run really ended, for a run reported after the process stopped
    ///   or resumed, since iOS keeps finishing uploads meanwhile. Counted now if nil.
    private func endRun(_ reason: CameraUploadRunEndReason, at date: Date, backlogEnd: Int? = nil) {
        guard let run = state.run else { return }
        sendTallies()
        let backlog = backlogEnd ?? backlogCount(mediaTypes: run.mediaTypes)
        sink.logEvent("cu_run_end", parameters: run.endParameters(reason, at: date, backlogEnd: backlog))

        state.run = nil
        persistNow()
        stopHeartbeatIfIdle()
        userProperties.refresh()
    }

    private func updateRun(_ update: (inout CameraUploadRunState) -> Void) {
        guard var run = state.run else { return }
        update(&run)
        run.lastActivityAt = Date()
        run.lastActivityInBackground = isInBackground
        state.run = run
        schedulePersist()
    }

    // MARK: - Failures and give-ups

    private func recordFailure(
        step: CameraUploadTelemetryStep,
        error: NSError?,
        isVideo: Bool,
        failuresSinceLaunch: Int,
        failuresSinceLogin: Int,
        at date: Date
    ) {
        let isGivenUp = state.countFailure(
            step: step.name,
            error: error,
            mediaType: isVideo ? "video" : "photo",
            failuresSinceLaunch: failuresSinceLaunch,
            failuresSinceLogin: failuresSinceLogin,
            runGroup: currentRunGroup(at: date),
            deviceNow: { deviceNow(includingThermalState: true) }
        )
        updateRun {
            $0.failed += 1
            if isGivenUp { $0.givenUp += 1 }
        }
        updateWake { $0.failed += 1 }

        if state.tallyStartedAt == nil {
            state.tallyStartedAt = date
            scheduleTallySending()
        }
        schedulePersist()
    }

    /// Sends one event per kind of failure and give-up counted since the last sending, then starts counting again.
    private func sendTallies() {
        guard state.hasTallies else { return }
        for event in state.tallyEvents {
            sink.logEvent(event.name, parameters: event.parameters)
        }
        let hadGiveUps = !state.giveUps.isEmpty
        state.clearTallies()
        tallySendingWorkItem?.cancel()
        tallySendingWorkItem = nil
        schedulePersist()
        if hadGiveUps {
            userProperties.refresh()
        }
    }

    private func scheduleTallySending() {
        tallySendingWorkItem?.cancel()
        let workItem = DispatchWorkItem { [weak self] in
            self?.sendTallies()
        }
        tallySendingWorkItem = workItem
        queue.asyncAfter(deadline: .now() + Constants.tallySendingInterval, execute: workItem)
    }

    // MARK: - Heat

    private func thermalStateDidChange(to newState: Int, at date: Date) {
        let oldState = thermalState
        guard newState != oldState else { return }
        thermalState = newState
        guard var run = state.run else { return }
        if run.countThermalChange(from: oldState, to: newState, at: date) {
            var parameters = run.group(at: date, appState: appStateName)
            parameters.merge(pipelineNow()) { $1 }
            parameters.merge(deviceNow(includingThermalState: false)) { $1 }
            parameters["trigger"] = .string(newState > oldState ? "escalation" : "de_escalation")
            parameters["from_thermal_state"] = .int(oldState)
            parameters["to_thermal_state"] = .int(newState)
            parameters["progress_view_visible"] = .bool(isProgressViewVisible)
            sink.logEvent("cu_thermal_change", parameters: parameters)
        }
        run.lastActivityAt = date
        run.lastActivityInBackground = isInBackground
        state.run = run
        schedulePersist()
    }

    // MARK: - Context groups

    private var appStateName: String {
        isInBackground ? "background" : "foreground"
    }

    /// The Run group of the current run, or placeholders when the event happens outside a run.
    private func currentRunGroup(at date: Date) -> CameraUploadTelemetryParameters {
        state.run?.group(at: date, appState: appStateName) ?? CameraUploadRunState.noRunGroup(appState: appStateName)
    }

    private func pipelineNow() -> CameraUploadTelemetryParameters {
        let uploading = CameraUploadRecordManager.shared().uploadingRecordsCount(error: nil)
        return pipeline.counts().group(uploading: Int(uploading), maxConcurrency: maxPhotoConcurrency + maxVideoConcurrency)
    }

    private func deviceNow(includingThermalState: Bool) -> CameraUploadTelemetryParameters {
        CameraUploadDeviceSnapshot.group(isCharging: isCharging, thermalState: includingThermalState ? thermalState : nil)
    }

    /// Files still to upload, given-up files not included.
    /// - Parameter mediaTypes: The media types to count, the currently enabled ones if nil.
    private func backlogCount(mediaTypes: [Int]?) -> Int {
        let types = mediaTypes.map { $0.map(NSNumber.init(value:)) } ?? CameraUploadManager.enabledMediaTypes
        let count = CameraUploadRecordManager.shared().pendingRecordsCount(mediaTypes: types, error: nil)
        return Int(count)
    }

    // MARK: - System notifications

    /// The observers live as long as the app, like the shared instance.
    private func observeSystemNotifications() {
        guard notificationObservers.isEmpty else { return }
        observeOnMain(UIApplication.didEnterBackgroundNotification) { [self] in
            refreshMainThreadState(isInBackground: true)
        }
        observeOnMain(UIApplication.willEnterForegroundNotification) { [self] in
            refreshMainThreadState(isInBackground: false)
        }
        observeOnMain(UIApplication.didBecomeActiveNotification) { [self] in
            let date = Date()
            queue.async { [self] in
                becameActiveAt = date
            }
        }
        observeOnMain(ProcessInfo.thermalStateDidChangeNotification) { [self] in
            let newState = CameraUploadDeviceSnapshot.thermalState
            let date = Date()
            refreshMainThreadState(isInBackground: nil)
            perform { [self] in
                thermalStateDidChange(to: newState, at: date)
            }
        }
    }

    private func observeOnMain(_ name: Notification.Name, handler: @escaping @MainActor @Sendable () -> Void) {
        let observer = NotificationCenter.default.addObserver(forName: name, object: nil, queue: .main) { _ in
            MainActor.assumeIsolated {
                handler()
            }
        }
        notificationObservers.append(observer)
    }

    /// Reads the values only available on the main thread and hands them to the queue.
    /// - Parameter newIsInBackground: The new app state, or nil to leave it unchanged.
    @MainActor
    private func refreshMainThreadState(isInBackground newIsInBackground: Bool?) {
        let charging = Self.readIsCharging()
        queue.async { [self] in
            isCharging = charging
            guard let newIsInBackground, newIsInBackground != isInBackground else { return }
            let now = Date()
            endRunIfSuspended(now: now)
            endWakeIfSuspended(now: now)
            isInBackground = newIsInBackground
            if newIsInBackground {
                hasRunInBackground = true
                updateRun { $0.wentBackground = true }
                startPeriodIfNeeded(at: now)
            } else {
                hasBeenInForeground = true
                updateRun { $0.backgroundTimeExpiredAt = nil }
                // Operations interrupted by a suspension carry on as soon as the app is back, before the raised
                // concurrency is noted, so the foreground is noted here.
                pendingTriggers["foreground"] = now
                endWake(.appOpened, at: now)
                // A time away left by an earlier process, with this one opened straight into the foreground.
                endPeriod(hasRunInBackground ? .appOpened : .relaunched, at: now)
                hasRunInBackground = false
                userProperties.refresh()
            }
        }
    }

    /// Battery monitoring is off in the app, and turning it on changes how the upload concurrency is calculated.
    /// So it is turned on only for this reading.
    @MainActor
    private static func readIsCharging() -> Bool {
        let device = UIDevice.current
        let wasMonitoring = device.isBatteryMonitoringEnabled
        device.isBatteryMonitoringEnabled = true
        let batteryState = device.batteryState
        device.isBatteryMonitoringEnabled = wasMonitoring
        return batteryState == .charging || batteryState == .full
    }

    // MARK: - Suspension

    private func startHeartbeat() {
        guard heartbeat == nil else { return }
        let timer = DispatchSource.makeTimerSource(queue: queue)
        timer.schedule(
            deadline: .now() + Constants.heartbeatInterval,
            repeating: Constants.heartbeatInterval,
            leeway: .seconds(1)
        )
        timer.setEventHandler { [weak self] in
            self?.heartbeatDidFire()
        }
        timer.resume()
        heartbeat = timer
    }

    private func stopHeartbeatIfIdle() {
        guard state.run == nil, state.wake == nil else { return }
        heartbeat?.cancel()
        heartbeat = nil
    }

    private func heartbeatDidFire() {
        let now = Date()
        endRunIfSuspended(now: now)
        endWakeIfSuspended(now: now)
        if let run = state.run {
            let backlog = backlogCount(mediaTypes: run.mediaTypes)
            updateRun { $0.lastKnownBacklog = backlog }
        }
        if state.wake != nil {
            let device = deviceNow(includingThermalState: true)
            let memory = CameraUploadDeviceSnapshot.memoryFootprintMB()
            let backlog = backlogCount(mediaTypes: nil)
            updateWake {
                $0.lastDeviceNow = device
                $0.lastKnownBacklog = backlog
                $0.memoryPeakMB = max($0.memoryPeakMB, memory)
            }
        }
    }

    /// Ends the run as suspended at its last activity, if the process did not run for a while in the background.
    private func endRunIfSuspended(now: Date) {
        guard isInBackground, let run = state.run,
              now.timeIntervalSince(run.lastActivityAt) > Constants.suspensionGap else { return }
        endRun(.suspended, at: run.lastActivityAt, backlogEnd: run.lastKnownBacklog)
    }

    /// Ends the wake-up at its last activity, if the process did not run for a while in the background.
    private func endWakeIfSuspended(now: Date) {
        guard isInBackground, let wake = state.wake,
              now.timeIntervalSince(wake.lastActivityAt) > Constants.suspensionGap else { return }
        endWake(
            wake.areUploadEventsDelivered ? .workDone : .suspended,
            at: wake.lastActivityAt,
            deviceNow: wake.lastDeviceNow,
            backlogEnd: wake.lastKnownBacklog
        )
    }

    // MARK: - Wake-up and time away handling

    private func startWake(_ type: CameraUploadWakeType, at date: Date) {
        guard isInBackground, state.wake == nil else { return }
        let isColdStart = !hasBeenInForeground && wakesInProcess == 0
        wakesInProcess += 1
        hasRunInBackground = true
        var wake = CameraUploadWakeState(
            type: type.name,
            startedAt: date,
            isColdStart: isColdStart,
            backlogStart: backlogCount(mediaTypes: nil),
            lastActivityAt: date
        )
        wake.readyAt = isNodeTreeCurrent ? date : nil
        wake.memoryPeakMB = CameraUploadDeviceSnapshot.memoryFootprintMB()
        wake.lastDeviceNow = deviceNow(includingThermalState: true)
        wake.lastKnownBacklog = wake.backlogStart
        state.wake = wake

        startPeriodIfNeeded(at: date)
        updatePeriod {
            $0.wakeCount += 1
            if isColdStart { $0.coldStartCount += 1 }
        }
        startHeartbeat()
        persistNow()
    }

    /// Sends cu_bg_wake, unless nothing was waiting and nothing happened.
    /// - Parameters:
    ///   - deviceNow: The Device now group, taken now if nil.
    ///   - backlogEnd: The backlog at the end, counted now if nil.
    private func endWake(
        _ reason: CameraUploadWakeEndReason,
        at date: Date,
        deviceNow device: CameraUploadTelemetryParameters? = nil,
        backlogEnd: Int? = nil
    ) {
        guard let wake = state.wake else { return }
        state.wake = nil
        persistNow()
        stopHeartbeatIfIdle()
        guard wake.hasAnythingHappened else { return }

        let memoryPeak = device == nil
            ? max(wake.memoryPeakMB, CameraUploadDeviceSnapshot.memoryFootprintMB())
            : wake.memoryPeakMB
        let parameters = wake.endParameters(
            reason,
            at: date,
            deviceNow: device ?? deviceNow(includingThermalState: true),
            memoryPeakMB: memoryPeak,
            backlogEnd: backlogEnd ?? backlogCount(mediaTypes: nil)
        )
        sink.logEvent("cu_bg_wake", parameters: parameters)
    }

    private func updateWake(_ update: (inout CameraUploadWakeState) -> Void) {
        guard var wake = state.wake else { return }
        update(&wake)
        wake.lastActivityAt = Date()
        state.wake = wake
        schedulePersist()
    }

    private func startPeriodIfNeeded(at date: Date) {
        guard state.period == nil else { return }
        state.period = CameraUploadPeriodState(startedAt: date, backlogStart: backlogCount(mediaTypes: nil))
        persistNow()
    }

    /// Sends cu_bg_period, unless the time away was short and nothing was done.
    private func endPeriod(_ reason: CameraUploadPeriodEndReason, at date: Date) {
        guard let period = state.period else { return }
        state.period = nil
        persistNow()
        guard period.isWorthSending(endingAt: date) else { return }

        let parameters = period.endParameters(reason, at: date, backlogEnd: backlogCount(mediaTypes: nil))
        sink.logEvent("cu_bg_period", parameters: parameters)
    }

    private func updatePeriod(_ update: (inout CameraUploadPeriodState) -> Void) {
        guard var period = state.period else { return }
        update(&period)
        state.period = period
        schedulePersist()
    }

    // MARK: - User properties

    /// Sets all user properties again, so a cleared local file starts with them.
    func resendUserProperties() {
        queue.async { [self] in
            userProperties.setAll()
        }
    }

    // MARK: - Analytics consent

    /// The app decided from the user's consent whether Firebase Analytics collects: at launch once the account is
    /// loaded, and when the cookie settings change. What was logged before is sent now, or dropped.
    func analyticsCollectionDidUpdate(isEnabled: Bool) {
        queue.async { [self] in
            sink.analyticsCollectionDidUpdate(isEnabled: isEnabled)
            if isEnabled {
                userProperties.setAll()
            }
        }
    }

    // MARK: - Persistence

    private func loadState() {
        guard state.isEmpty, let saved = stateStore.load() else { return }
        state = saved
    }

    private func schedulePersist() {
        // In the background the app can be suspended at any moment, and a delayed save would wait until it resumes.
        guard !isInBackground else {
            persistNow()
            return
        }
        guard persistWorkItem == nil else { return }
        let workItem = DispatchWorkItem { [weak self] in
            self?.persistNow()
        }
        persistWorkItem = workItem
        queue.asyncAfter(deadline: .now() + Constants.persistDelay, execute: workItem)
    }

    private func persistNow() {
        persistWorkItem?.cancel()
        persistWorkItem = nil
        stateStore.save(state)
    }
}
