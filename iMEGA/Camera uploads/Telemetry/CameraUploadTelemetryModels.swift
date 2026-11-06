import Foundation

/// What made Camera Upload look for files to queue. The latest one noted before a run starts becomes its trigger.
@objc enum CameraUploadRunTrigger: Int {
    case settingsChanged
    case nodesReady
    case networkBack
    case resumed
    case libraryChanged
    /// The allowed concurrency went up, e.g. because the app came to the foreground or the device cooled down.
    case concurrencyChanged
    case backgroundRefresh
    case backgroundProcessing
    case backgroundUploadEvents

    var name: String {
        switch self {
        case .settingsChanged: "settings_changed"
        case .nodesReady: "nodes_ready"
        case .networkBack: "network_back"
        case .resumed: "resumed"
        case .libraryChanged: "library_changed"
        case .concurrencyChanged: "concurrency_changed"
        case .backgroundRefresh: "bg_refresh"
        case .backgroundProcessing: "bg_processing"
        case .backgroundUploadEvents: "bg_upload_events"
        }
    }
}

/// Why uploading was paused. A pause ends the current run.
@objc enum CameraUploadPauseReason: Int {
    case overQuota
    case diskFull
    case businessExpired

    var endReason: CameraUploadRunEndReason {
        switch self {
        case .overQuota: .pausedOverQuota
        case .diskFull: .pausedStorageFull
        case .businessExpired: .pausedBusinessExpired
        }
    }
}

enum CameraUploadRunEndReason: String, Codable {
    case queueEmpty = "queue_empty"
    case pausedOverQuota = "paused_over_quota"
    case pausedStorageFull = "paused_storage_full"
    case pausedBusinessExpired = "paused_business_expired"
    case disabled
    case loggedOut = "logged_out"
    case suspended
    /// The process stopped while the app was in the foreground: a crash, or the app being stopped from Xcode.
    case killed
    /// Found at the next launch: the process stopped while the app was in the background. Usually the app was
    /// suspended, then ended by iOS or swiped away; iOS ending it while it was still running looks the same.
    case endedInBackground = "ended_in_background"
}

/// The step a file failed at.
@objc enum CameraUploadTelemetryStep: Int {
    /// Before the original is fetched: building the operation, creating its working directory.
    case prepare
    case fetchOriginal
    case export
    case thumbnail
    case encrypt
    case requestUploadURL
    case transfer
    case createNode

    var name: String {
        switch self {
        case .prepare: "prepare"
        case .fetchOriginal: "fetch_original"
        case .export: "export"
        case .thumbnail: "thumbnail"
        case .encrypt: "encrypt"
        case .requestUploadURL: "request_upload_url"
        case .transfer: "transfer"
        case .createNode: "create_node"
        }
    }
}

/// Where an upload operation is in the pipeline, for the Pipeline now group.
@objc enum CameraUploadPipelineStage: Int {
    case queued
    case fetching
    case exporting
    case thumbnailing
    case encrypting
    case requestingUploadURL

    var isPreparing: Bool {
        switch self {
        case .fetching, .exporting, .thumbnailing, .encrypting: true
        case .queued, .requestingUploadURL: false
        }
    }
}

/// What woke the app in the background.
@objc enum CameraUploadWakeType: Int {
    case backgroundRefresh
    /// The longer background task the system runs while the device is charging, typically overnight.
    case backgroundProcessing
    case backgroundUploadEvents

    var name: String {
        switch self {
        case .backgroundRefresh: "bg_refresh"
        case .backgroundProcessing: "bg_processing"
        case .backgroundUploadEvents: "bg_upload_events"
        }
    }
}

enum CameraUploadWakeEndReason: String, Codable {
    /// iOS ended the background time.
    case timeExpired = "time_expired"
    /// The background refresh or processing task finished, or iOS had delivered all upload events.
    case workDone = "work_done"
    case appOpened = "app_opened"
    /// iOS suspended or ended the app without any notice, found afterwards.
    case suspended
}

enum CameraUploadPeriodEndReason: String, Codable {
    case appOpened = "app_opened"
    /// The app was launched into the foreground after it had been ended while away.
    case relaunched
}

/// How a file was put aside without counting as a failure.
@objc enum CameraUploadPutAsideReason: Int {
    case diskFull
    case offline
    case overQuota
}

// MARK: - Persisted state

/// Counters of the running run. Kept on disk so a run ended by iOS can be reported at the next launch.
struct CameraUploadRunState: Codable {
    let id: String
    let trigger: String
    let appState: String
    let startedAt: Date
    let backlogStart: Int
    /// The last moment the process was known to be running during the run.
    var lastActivityAt: Date
    /// Whether the app was in the background at `lastActivityAt`.
    var lastActivityInBackground: Bool?
    /// When background time last ran out during the run, cleared when the app comes back to the foreground.
    var backgroundTimeExpiredAt: Date?
    /// The media types Camera Upload handled when the run started, to count the backlog the same way at its end,
    /// also when the run ends because Camera Upload was switched off.
    var mediaTypes: [Int]?
    /// The backlog at the last heartbeat, sent as backlog_end when the run is reported after the process stopped.
    var lastKnownBacklog: Int?
    var wentBackground = false
    var wentOffline = false
    var handedOver = 0
    var uploaded = 0
    var alreadyInCloud = 0
    var putAside = 0
    var failed = 0
    var givenUp = 0
    var videosHandedOver = 0
    var videosUploaded = 0
    var peakThermalState: Int
    var seriousOrWorseSeconds: Double = 0
    var seriousSince: Date?
    var thermalChanges = 0
    var thermalEventsSent = 0
    /// When the device last became warmer to each level, to merge quick back-and-forth changes.
    var lastEscalationAt: [Int: Date] = [:]

    init(id: String, trigger: String, appState: String, startedAt: Date, backlogStart: Int, thermalState: Int) {
        self.id = id
        self.trigger = trigger
        self.appState = appState
        self.startedAt = startedAt
        self.backlogStart = backlogStart
        lastActivityAt = startedAt
        peakThermalState = thermalState
        seriousSince = thermalState >= 2 ? startedAt : nil
    }
}

/// One background wake-up, kept on disk so it can be reported if iOS ends the app meanwhile.
struct CameraUploadWakeState: Codable {
    let type: String
    let startedAt: Date
    let isColdStart: Bool
    let backlogStart: Int
    var readyAt: Date?
    var lastActivityAt: Date
    var handedOver = 0
    var uploaded = 0
    var failed = 0
    var memoryPeakMB = 0
    /// Set once iOS has delivered all events of the background upload session.
    var areUploadEventsDelivered = false
    /// The Device now group and backlog at the last heartbeat, for a wake-up that is found ended afterwards.
    var lastDeviceNow: CameraUploadTelemetryParameters = [:]
    var lastKnownBacklog: Int?

    var hasAnythingHappened: Bool {
        backlogStart > 0 || handedOver > 0 || uploaded > 0 || failed > 0
    }
}

/// The time the app spends away, from going to the background until it is opened again.
struct CameraUploadPeriodState: Codable {
    let startedAt: Date
    let backlogStart: Int
    var wakeCount = 0
    var coldStartCount = 0
    var handedOver = 0
    var uploaded = 0

    /// A short time away with nothing done only says the user switched apps for a moment, so it is not sent.
    func isWorthSending(endingAt date: Date) -> Bool {
        wakeCount > 0 || handedOver > 0 || uploaded > 0 || (backlogStart > 0 && date.timeIntervalSince(startedAt) >= 60)
    }
}

struct CameraUploadFailureKind: Hashable, Codable {
    let step: String
    let errorDomain: String
    let errorCode: Int
    let mediaType: String
}

struct CameraUploadFailureTally: Codable {
    let context: CameraUploadTelemetryParameters
    var occurrences = 0
    var retryOccurrences = 0
}

struct CameraUploadGiveUpKind: Hashable, Codable {
    let limit: String
    let lastStep: String
    let errorDomain: String
    let errorCode: Int
    let mediaType: String
}

struct CameraUploadGiveUpTally: Codable {
    let context: CameraUploadTelemetryParameters
    var files = 0
    var failuresSinceLoginMax = 0
}

struct CameraUploadTelemetryState: Codable {
    var run: CameraUploadRunState?
    var wake: CameraUploadWakeState?
    var period: CameraUploadPeriodState?
    var failures: [CameraUploadFailureKind: CameraUploadFailureTally] = [:]
    var giveUps: [CameraUploadGiveUpKind: CameraUploadGiveUpTally] = [:]
    /// When the oldest unsent failure or give-up was counted.
    var tallyStartedAt: Date?

    var hasTallies: Bool {
        !failures.isEmpty || !giveUps.isEmpty
    }

    var isEmpty: Bool {
        run == nil && wake == nil && period == nil && !hasTallies
    }
}
