import AVFoundation
import Foundation
import Photos

/// Failures and given-up files are counted per kind, then sent together with one event per kind.
extension CameraUploadTelemetryState {
    private enum TallyConstants {
        static let maxKindsPerSending = 50
        /// MaximumUploadRetryPerLaunchCount and MaximumUploadRetryPerLoginCount in CameraUploadRecordManager.m.
        static let perLaunchRetryLimit = 7
        static let perLoginRetryLimit = 7 * 77
        static let knownErrorDomains: Set<String> = [
            NSURLErrorDomain,
            PHPhotosErrorDomain,
            AVFoundationErrorDomain,
            NSCocoaErrorDomain,
            NSPOSIXErrorDomain,
            NSOSStatusErrorDomain,
            "CloudPhotoLibraryErrorDomain",
            "nz.mega.MEGAError",
            "nz.mega.cameraUpload"
        ]
    }

    /// Counts a failure, and a give-up when it is the first failure past a retry limit.
    /// - Parameters:
    ///   - failuresSinceLaunch: The file's failures since launch, this one included.
    ///   - failuresSinceLogin: The file's failures since login, this one included.
    ///   - runGroup: The Run group now, kept with a new kind.
    ///   - deviceNow: The Device now group, read only for a new kind of failure.
    /// - Returns: Whether the file was given up.
    mutating func countFailure(
        step: String,
        error: NSError?,
        mediaType: String,
        failuresSinceLaunch: Int,
        failuresSinceLogin: Int,
        runGroup: CameraUploadTelemetryParameters,
        deviceNow: () -> CameraUploadTelemetryParameters
    ) -> Bool {
        let (errorDomain, errorCode) = Self.cleaned(error)

        var failureKind = CameraUploadFailureKind(
            step: step, errorDomain: errorDomain, errorCode: errorCode, mediaType: mediaType)
        if failures[failureKind] == nil, failures.count >= TallyConstants.maxKindsPerSending {
            failureKind = CameraUploadFailureKind(step: step, errorDomain: "overflow", errorCode: 0, mediaType: mediaType)
        }
        var failureTally = failures[failureKind]
            ?? CameraUploadFailureTally(context: runGroup.merging(deviceNow()) { $1 })
        failureTally.occurrences += 1
        if failuresSinceLogin > 1 {
            failureTally.retryOccurrences += 1
        }
        failures[failureKind] = failureTally

        let limit: String? = if failuresSinceLogin == TallyConstants.perLoginRetryLimit + 1 {
            "login"
        } else if failuresSinceLaunch == TallyConstants.perLaunchRetryLimit + 1 {
            "launch"
        } else {
            nil
        }
        guard let limit else { return false }

        var giveUpKind = CameraUploadGiveUpKind(
            limit: limit, lastStep: step, errorDomain: errorDomain, errorCode: errorCode, mediaType: mediaType)
        if giveUps[giveUpKind] == nil, giveUps.count >= TallyConstants.maxKindsPerSending {
            giveUpKind = CameraUploadGiveUpKind(
                limit: limit, lastStep: step, errorDomain: "overflow", errorCode: 0, mediaType: mediaType)
        }
        var giveUpTally = giveUps[giveUpKind] ?? CameraUploadGiveUpTally(context: runGroup)
        giveUpTally.files += 1
        giveUpTally.failuresSinceLoginMax = max(giveUpTally.failuresSinceLoginMax, failuresSinceLogin)
        giveUps[giveUpKind] = giveUpTally
        return true
    }

    /// One cu_file_failed per kind of failure and one cu_file_given_up per kind of give-up, the most frequent first.
    var tallyEvents: [(name: String, parameters: CameraUploadTelemetryParameters)] {
        var events: [(name: String, parameters: CameraUploadTelemetryParameters)] = []
        for (kind, tally) in failures.sorted(by: { $0.value.occurrences > $1.value.occurrences }) {
            var parameters = tally.context
            parameters["step"] = .string(kind.step)
            parameters["error_domain"] = .string(kind.errorDomain)
            parameters["error_code"] = .int(kind.errorCode)
            parameters["media_type"] = .string(kind.mediaType)
            parameters["occurrences"] = .int(tally.occurrences)
            parameters["retry_occurrences"] = .int(tally.retryOccurrences)
            events.append((name: "cu_file_failed", parameters: parameters))
        }
        for (kind, tally) in giveUps.sorted(by: { $0.value.files > $1.value.files }) {
            var parameters = tally.context
            parameters["limit"] = .string(kind.limit)
            parameters["last_step"] = .string(kind.lastStep)
            parameters["error_domain"] = .string(kind.errorDomain)
            parameters["error_code"] = .int(kind.errorCode)
            parameters["media_type"] = .string(kind.mediaType)
            parameters["files"] = .int(tally.files)
            parameters["failures_since_login_max"] = .int(tally.failuresSinceLoginMax)
            events.append((name: "cu_file_given_up", parameters: parameters))
        }
        return events
    }

    mutating func clearTallies() {
        failures = [:]
        giveUps = [:]
        tallyStartedAt = nil
    }

    /// Keeps the error domain to a known list, so a domain that carries a file name or path cannot turn every
    /// failure into a new kind.
    private static func cleaned(_ error: NSError?) -> (domain: String, code: Int) {
        guard let error else { return ("none", 0) }
        let domain = TallyConstants.knownErrorDomains.contains(error.domain) ? error.domain : "other"
        return (domain, error.code)
    }
}
