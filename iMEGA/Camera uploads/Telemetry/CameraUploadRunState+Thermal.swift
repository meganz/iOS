import Foundation

extension CameraUploadRunState {
    private enum ThermalConstants {
        static let maxEventsPerRun = 20
        /// A change to a warmer level this soon after the last change to the same level is counted but not sent.
        static let escalationMergeWindow: TimeInterval = 5
    }

    /// Counts a change of the thermal state during the run.
    /// - Returns: Whether to send cu_thermal_change for it.
    mutating func countThermalChange(from oldState: Int, to newState: Int, at date: Date) -> Bool {
        thermalChanges += 1
        peakThermalState = max(peakThermalState, newState)
        if newState >= 2, seriousSince == nil {
            seriousSince = date
        } else if newState < 2, let since = seriousSince {
            seriousOrWorseSeconds += max(date.timeIntervalSince(since), 0)
            seriousSince = nil
        }

        var isMerged = false
        if newState > oldState {
            if let last = lastEscalationAt[newState],
               date.timeIntervalSince(last) < ThermalConstants.escalationMergeWindow {
                isMerged = true
            }
            lastEscalationAt[newState] = date
        }
        guard !isMerged, thermalEventsSent < ThermalConstants.maxEventsPerRun else { return false }
        thermalEventsSent += 1
        return true
    }

    /// The time spent serious or critical until `date`, including a stretch still going on.
    func seriousOrWorseSeconds(until date: Date) -> TimeInterval {
        guard let seriousSince else { return seriousOrWorseSeconds }
        return seriousOrWorseSeconds + max(date.timeIntervalSince(seriousSince), 0)
    }
}
