#if arch(arm64)
import Darwin
import Dispatch
import Foundation

// ARM64 thread state count
private let ARM_THREAD_STATE64_COUNT = mach_msg_type_number_t(
    MemoryLayout<arm_thread_state64_t>.size / MemoryLayout<natural_t>.size
)

final class APMThreadCallStack {
    static let mainThreadMachPortLock = NSLock()
    nonisolated(unsafe) static var mainThreadMachPort: mach_port_t?
    
    static func storeMainThreadHandle() {
        if Thread.isMainThread {
            storeMainThreadPort()
        } else {
            DispatchQueue.main.async(execute: storeMainThreadPort)
        }
    }
    
    private static func storeMainThreadPort() {
        assert(Thread.isMainThread, "You should call storeMainThreadPort() from the main thread only")
        mainThreadMachPortLock.lock()
        defer { mainThreadMachPortLock.unlock() }
        
        guard mainThreadMachPort == nil else {
            return
        }

        mainThreadMachPort = mach_thread_self()
    }
    
    // MARK: - Mach Stack Capture
    static func captureMainThreadStack() -> [UInt64]? {
        assert(!Thread.isMainThread, "captureMainThreadStack() should be called from a background thread only.")

        guard let mainThread = getMainThreadHandle() else {
            return nil
        }
        
        guard let stackAddresses = captureThreadStack(on: mainThread) else {
            return nil
        }
        return stackAddresses
    }
    
    /// Get main thread handle from all threads
    private static func getMainThreadHandle() -> thread_t? {
        mainThreadMachPortLock.lock()
        defer { mainThreadMachPortLock.unlock() }
        return mainThreadMachPort
    }
    
    private static func captureThreadStack(on thread: thread_t) -> [UInt64]? {
        var addresses: [UInt64] = []
        
        // Suspend the thread (CRITICAL SECTION)
        let suspendResult = thread_suspend(thread)
        guard suspendResult == KERN_SUCCESS else {
            return nil
        }
        
        // Ensure thread is always resumed
        defer {
            thread_resume(thread)
        }
        // Get thread state
        var state = arm_thread_state64_t()
        var stateCount = mach_msg_type_number_t(ARM_THREAD_STATE64_COUNT)
        let flavor = thread_state_flavor_t(ARM_THREAD_STATE64)
        
        let getStateResult = withUnsafeMutablePointer(to: &state) { statePtr in
            statePtr.withMemoryRebound(to: natural_t.self, capacity: Int(stateCount)) { naturalPtr in
                thread_get_state(thread, flavor, naturalPtr, &stateCount)
            }
        }
        
        guard getStateResult == KERN_SUCCESS else {
            return nil
        }
        
        // Backtrace from thread state
        addresses = backtraceFromARM64State(state: state)
        return addresses.isEmpty ? nil : addresses
    }
    
    private static func backtraceFromARM64State(state: arm_thread_state64_t) -> [UInt64] {
        var addresses: [UInt64] = []
        let maxFrames = 128
        
        let pc = state.__pc // PC (Program Counter) - current instruction
        addresses.append(pc)
        let lr = state.__lr // LR (Link Register) - return address
        if lr != 0 {
            addresses.append(lr)
        }
        
        // Walk frame pointer (FP) chain
        var fp = state.__fp
        for _ in 0..<maxFrames {
            guard fp != 0 && fp >= 0x1000 else {
                break
            }
            
            // Read return address from frame
            // Frame layout: [previous FP][return address]
            let returnAddressPtr = fp + 8
            var returnAddress: UInt64 = 0
            
            let readResult = readMemory(
                address: returnAddressPtr,
                buffer: &returnAddress,
                size: MemoryLayout<UInt64>.size
            )
            
            guard readResult == KERN_SUCCESS else {
                break
            }
            
            // Validate return address
            guard returnAddress != 0 && returnAddress >= 0x1000 else {
                break
            }
            
            addresses.append(returnAddress)
            
            // Read previous frame pointer
            var previousFP: UInt64 = 0
            let fpReadResult = readMemory(
                address: fp,
                buffer: &previousFP,
                size: MemoryLayout<UInt64>.size
            )
            
            guard fpReadResult == KERN_SUCCESS else {
                break
            }
            
            // Validate frame pointer progression
            guard previousFP > fp else {
                break
            }
            
            fp = previousFP
        }
        
        return addresses
    }
    
    // MARK: - Memory Reading
    private static func readMemory(address: UInt64, buffer: UnsafeMutableRawPointer, size: Int) -> kern_return_t {
        guard size > 0 else {
            return KERN_INVALID_ARGUMENT
        }

        var bytesRead: vm_size_t = 0
        let kr = vm_read_overwrite(
            mach_task_self_,
            vm_address_t(address),
            vm_size_t(size),
            vm_address_t(UInt(bitPattern: buffer)),
            &bytesRead
        )
        return kr
    }
}

#endif
