import Darwin
import Foundation

/// One-off readings of the app's CPU and memory use, for the Device now group.
enum CameraUploadDeviceSnapshot {
    /// CPU use of the whole app, summed over its threads. 100 = one core fully busy. The kernel keeps each thread's
    /// value as a short decaying average, and threads that already exited are not included. -1 if it can't be read.
    static func cpuPercent() -> Double {
        var threads: thread_act_array_t?
        var threadCount: mach_msg_type_number_t = 0
        guard task_threads(mach_task_self_, &threads, &threadCount) == KERN_SUCCESS, let threads else {
            return -1
        }
        defer {
            for index in 0..<Int(threadCount) {
                mach_port_deallocate(mach_task_self_, threads[index])
            }
            vm_deallocate(
                mach_task_self_,
                vm_address_t(UInt(bitPattern: threads)),
                vm_size_t(Int(threadCount) * MemoryLayout<thread_t>.stride)
            )
        }

        let infoCount = MemoryLayout<thread_basic_info_data_t>.size / MemoryLayout<natural_t>.size
        var total = 0.0
        for index in 0..<Int(threadCount) {
            var info = thread_basic_info_data_t()
            var count = mach_msg_type_number_t(infoCount)
            let result = withUnsafeMutablePointer(to: &info) {
                $0.withMemoryRebound(to: integer_t.self, capacity: infoCount) {
                    thread_info(threads[index], thread_flavor_t(THREAD_BASIC_INFO), $0, &count)
                }
            }
            guard result == KERN_SUCCESS, info.flags & TH_FLAGS_IDLE == 0 else { continue }
            total += Double(info.cpu_usage) / Double(TH_USAGE_SCALE) * 100
        }
        return total
    }

    /// The memory footprint iOS judges the app by, in MB. -1 if it can't be read.
    static func memoryFootprintMB() -> Int {
        var info = task_vm_info_data_t()
        var count = mach_msg_type_number_t(MemoryLayout<task_vm_info_data_t>.size / MemoryLayout<integer_t>.size)
        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                task_info(mach_task_self_, task_flavor_t(TASK_VM_INFO), $0, &count)
            }
        }
        guard result == KERN_SUCCESS else { return -1 }
        return Int(info.phys_footprint / 1024 / 1024)
    }

    static var thermalState: Int {
        switch ProcessInfo.processInfo.thermalState {
        case .nominal: 0
        case .fair: 1
        case .serious: 2
        case .critical: 3
        @unknown default: -1
        }
    }
}
