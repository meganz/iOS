@preconcurrency import Darwin

struct MemoryUsage {
    
    private init(
        used: Int64,
        peak: Int64,
        remaining: Int64
    ) {
        self.used = used
        self.peak = peak
        self.remaining = remaining
    }
    
    static let formatter = ByteCountFormatter()
    let used: Int64
    let peak: Int64
    let remaining: Int64
    
    static var vmInfo: task_vm_info? {
        let vmInfoExpectedSize = MemoryLayout<task_vm_info_data_t>.size / MemoryLayout<natural_t>.size
        var vmInfo = task_vm_info_data_t()
        var vmInfoSize = mach_msg_type_number_t(vmInfoExpectedSize)
        
        let kern: kern_return_t = withUnsafeMutablePointer(to: &vmInfo) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                          task_flavor_t(TASK_VM_INFO),
                          $0,
                          &vmInfoSize)
            }
        }
        
        guard kern == KERN_SUCCESS else {
            return nil
        }
        return vmInfo
    }
    
    init?() {
        
        guard let info = Self.vmInfo else {
            return nil
        }
        
        let usage = MemoryUsage(
            used: Int64(info.phys_footprint),
            peak: Int64(info.ledger_phys_footprint_peak),
            remaining: Int64(info.limit_bytes_remaining)
        )
        
        self = usage
    }
    
    var formattedDescription: String {
        "used: \(Self.formatter.string(fromByteCount: used)) peak: \(Self.formatter.string(fromByteCount: peak)) remaining: \(Self.formatter.string(fromByteCount: remaining))"
    }
}
