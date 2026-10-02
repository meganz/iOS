import Darwin
import Foundation

/// Memory numbers of this process, in MiB (1,048,576 bytes), the unit of the Xcode memory gauge.
public enum Footprint {
    static let mebibyte = 1_048_576.0

    /// Physical footprint in MiB. Same number as Xcode's memory gauge and the jetsam limit.
    /// Nil when `task_info` fails, so a failed read never looks like 0.
    /// Pages freed and then reused inside one process are not counted again, so a repeated run under-reports.
    public static func currentMiB() -> Double? {
        var info = task_vm_info_data_t()
        var count = mach_msg_type_number_t(MemoryLayout<task_vm_info_data_t>.size / MemoryLayout<integer_t>.size)
        let result = withUnsafeMutablePointer(to: &info) { pointer in
            pointer.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                task_info(mach_task_self_, task_flavor_t(TASK_VM_INFO), $0, &count)
            }
        }
        guard result == KERN_SUCCESS, info.phys_footprint > 0 else { return nil }
        return Double(info.phys_footprint) / mebibyte
    }

    /// Bytes in use in all malloc zones, in MiB. Counts every live heap object, also on a repeated run.
    /// It does not count memory from `vm_allocate` or `mmap`, like image buffers.
    public static func heapMiB() -> Double {
        var statistics = malloc_statistics_t()
        malloc_zone_statistics(nil, &statistics)
        return Double(statistics.size_in_use) / mebibyte
    }
}

enum BenchmarkMetricError: Error {
    /// `task_info` failed at the start of the interval, so no footprint number is real.
    case footprintReadFailed
    /// The sampler never ran. A silent 0 would look like a measured peak.
    case noSamples
    /// The display link never fired. A silent 0 would look like a smooth run.
    case noFrames
}
