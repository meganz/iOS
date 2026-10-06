import Darwin
import Foundation
import os

/// Logs the extension's memory footprint while the replicated extension is being validated against the 20MB
/// extension limit, mostly around CloudRAID downloads. Removed together with the switch to the replicated
/// extension.
///
/// Logs through `os.Logger` rather than `MEGALog*`: it needs no in-app logging toggle, works before the SDK exists,
/// and the lines survive jetsam killing the process mid-download. Read them in Console.app, filtering on `FPMEM`.
///
/// - `footprint`: the current `phys_footprint`, which jetsam compares against the limit.
/// - `peak`: the highest footprint over the process lifetime.
/// - `available`: `os_proc_available_memory()`, the headroom left before jetsam.
enum FileProviderMemoryProbe {
    private static let logger = Logger(subsystem: "mega.ios.fileprovider.memory", category: "FPMEM")
    private static let megabyte = 1024.0 * 1024.0

    static func mark(_ label: String) {
        guard let info = vmInfo() else {
            logger.error("[FPMEM] \(label, privacy: .public) task_info failed")
            return
        }
        let footprint = megabytes(info.phys_footprint)
        let peak = megabytes(info.ledger_phys_footprint_peak)
        let available = megabytes(os_proc_available_memory())
        let message = "[FPMEM] pid=\(getpid()) \(label) footprint=\(footprint)MB peak=\(peak)MB available=\(available)MB"
        logger.notice("\(message, privacy: .public)")
    }

    /// Logs a sample every `interval` until the returned task is cancelled, so the trend right before a jetsam kill
    /// is visible. Detached so that sampling does not depend on the caller's task making progress.
    /// - Parameter detail: Appended to every sample, for state that changes while sampling.
    static func startSampling(
        _ label: String,
        interval: Duration = .milliseconds(250),
        detail: @escaping @Sendable () -> String = { "" }
    ) -> Task<Void, Never> {
        Task.detached(priority: .utility) {
            var sample = 0
            while !Task.isCancelled {
                mark("\(label) sample=\(sample) \(detail())")
                sample += 1
                try? await Task.sleep(for: interval)
            }
        }
    }

    private static func megabytes(_ bytes: some BinaryInteger) -> String {
        String(format: "%.2f", Double(bytes) / megabyte)
    }

    private static func vmInfo() -> task_vm_info_data_t? {
        var info = task_vm_info_data_t()
        var count = mach_msg_type_number_t(MemoryLayout<task_vm_info_data_t>.size / MemoryLayout<integer_t>.size)
        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                task_info(mach_task_self_, task_flavor_t(TASK_VM_INFO), $0, &count)
            }
        }
        return result == KERN_SUCCESS ? info : nil
    }
}
