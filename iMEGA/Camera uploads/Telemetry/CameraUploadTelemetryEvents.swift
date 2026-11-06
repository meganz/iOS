import Foundation

// MARK: - Run

extension CameraUploadRunState {
    /// The Run group as at the start of the run.
    var group: CameraUploadTelemetryParameters {
        [
            "run_id": .string(id),
            "run_trigger": .string(trigger),
            "app_state": .string(appState)
        ]
    }

    /// The Run group at `date`, with the app state then.
    func group(at date: Date, appState currentAppState: String) -> CameraUploadTelemetryParameters {
        var parameters = group
        parameters["app_state"] = .string(currentAppState)
        parameters["run_elapsed_s"] = .rounded(max(date.timeIntervalSince(startedAt), 0))
        return parameters
    }

    /// The Run group of an event outside a run.
    static func noRunGroup(appState: String) -> CameraUploadTelemetryParameters {
        [
            "run_id": .string("none"),
            "run_trigger": .string("none"),
            "app_state": .string(appState),
            "run_elapsed_s": .int(-1)
        ]
    }

    /// The parameters of cu_run_end.
    func endParameters(
        _ reason: CameraUploadRunEndReason,
        at date: Date,
        backlogEnd: Int
    ) -> CameraUploadTelemetryParameters {
        var parameters = group
        parameters["end_reason"] = .string(reason.rawValue)
        parameters["went_background"] = .bool(wentBackground)
        parameters["went_offline"] = .bool(wentOffline)
        parameters["duration_s"] = .rounded(max(date.timeIntervalSince(startedAt), 0))
        parameters["handed_over"] = .int(handedOver)
        parameters["uploaded"] = .int(uploaded)
        parameters["already_in_cloud"] = .int(alreadyInCloud)
        parameters["put_aside"] = .int(putAside)
        parameters["failed"] = .int(failed)
        parameters["given_up"] = .int(givenUp)
        parameters["backlog_start"] = .int(backlogStart)
        parameters["backlog_end"] = .int(backlogEnd)
        parameters["videos_handed_over"] = .int(videosHandedOver)
        parameters["videos_uploaded"] = .int(videosUploaded)
        parameters["peak_thermal_state"] = .int(peakThermalState)
        parameters["serious_or_worse_s"] = .rounded(seriousOrWorseSeconds(until: date))
        parameters["thermal_changes"] = .int(thermalChanges)
        return parameters
    }
}

// MARK: - Background wake-up and time away

extension CameraUploadWakeState {
    /// The parameters of cu_bg_wake.
    func endParameters(
        _ reason: CameraUploadWakeEndReason,
        at date: Date,
        deviceNow: CameraUploadTelemetryParameters,
        memoryPeakMB: Int,
        backlogEnd: Int
    ) -> CameraUploadTelemetryParameters {
        var parameters = deviceNow
        parameters["wake_type"] = .string(type)
        parameters["cold_start"] = .bool(isColdStart)
        parameters["time_to_ready_s"] = readyAt.map {
            CameraUploadTelemetryValue.rounded($0.timeIntervalSince(startedAt))
        } ?? .int(-1)
        parameters["duration_s"] = .rounded(max(date.timeIntervalSince(startedAt), 0))
        parameters["handed_over"] = .int(handedOver)
        parameters["uploaded"] = .int(uploaded)
        parameters["failed"] = .int(failed)
        parameters["end_reason"] = .string(reason.rawValue)
        parameters["backlog_end"] = .int(backlogEnd)
        parameters["memory_peak_mb"] = .int(memoryPeakMB)
        return parameters
    }
}

extension CameraUploadPeriodState {
    /// The parameters of cu_bg_period.
    func endParameters(
        _ reason: CameraUploadPeriodEndReason,
        at date: Date,
        backlogEnd: Int
    ) -> CameraUploadTelemetryParameters {
        [
            "duration_min": .rounded(max(date.timeIntervalSince(startedAt), 0) / 60),
            "wake_count": .int(wakeCount),
            "cold_start_count": .int(coldStartCount),
            "handed_over": .int(handedOver),
            "uploaded": .int(uploaded),
            "backlog_start": .int(backlogStart),
            "backlog_end": .int(backlogEnd),
            "ended_by": .string(reason.rawValue)
        ]
    }
}

// MARK: - Context groups

extension CameraUploadPipelineMonitor.Counts {
    /// The Pipeline now group.
    /// - Parameters:
    ///   - uploading: Files handed over to the background session and not finished yet.
    ///   - maxConcurrency: The allowed number of photo and video operations together.
    func group(uploading: Int, maxConcurrency: Int) -> CameraUploadTelemetryParameters {
        [
            "queued": .int(queued),
            "fetching": .int(fetching),
            "exporting": .int(exporting),
            "thumbnailing": .int(thumbnailing),
            "encrypting": .int(encrypting),
            "requesting_url": .int(requestingUploadURL),
            "uploading": .int(uploading),
            "videos_preparing": .int(videosPreparing),
            "max_concurrency": .int(maxConcurrency)
        ]
    }
}

extension CameraUploadDeviceSnapshot {
    /// The Device now group. `thermalState` nil leaves it out, for an event that sends it under other names.
    static func group(isCharging: Bool, thermalState: Int?) -> CameraUploadTelemetryParameters {
        var parameters: CameraUploadTelemetryParameters = [
            "cpu_pct": .rounded(cpuPercent()),
            "memory_mb": .int(memoryFootprintMB()),
            "is_charging": .bool(isCharging),
            "low_power_mode": .bool(ProcessInfo.processInfo.isLowPowerModeEnabled)
        ]
        if let thermalState {
            parameters["thermal_state"] = .int(thermalState)
        }
        return parameters
    }
}
