import Foundation
import UIKit

enum CameraUploadMediaTypePausedReason: Sendable, Equatable {
    enum ThermalState: Sendable, Equatable {
        case critical
        case serious
    }
    case lowBattery
    case thermalState(ThermalState)
}

@objc class CameraUploadConcurrentCountCalculator: NSObject {
    private var currentUploadQueueStates = CameraUploadQueueStates(
            photoUploadState: .defaultMaximum,
            videoUploadState: .defaultMaximum)
    
    // MARK: - Notifications to monitor
    
    @objc func startCalculatingConcurrentCount() {
        NotificationCenter.default.removeObserver(self)
        
        NotificationCenter.default.addObserver(self, selector: #selector(applicationStatesChangedNotification(_:)), name: UIApplication.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(applicationStatesChangedNotification(_:)), name: UIApplication.didBecomeActiveNotification, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(applicationStatesChangedNotification(_:)), name: UIDevice.batteryStateDidChangeNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(applicationStatesChangedNotification(_:)), name: UIDevice.batteryLevelDidChangeNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(applicationStatesChangedNotification(_:)), name: Notification.Name.NSProcessInfoPowerStateDidChange, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(applicationStatesChangedNotification(_:)), name: ProcessInfo.thermalStateDidChangeNotification, object: nil)
    }
    
    @objc func stopCalculatingConcurrentCount() {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private func applicationStatesChangedNotification(_ notification: Notification) {
        MEGALogDebug("[Camera Upload] concurrent calculator received \(notification.name)")
        Task { @MainActor in
            let uploadQueueState = calculateCameraUploadQueueStates()
            
            if currentUploadQueueStates.photoConcurrentCount != uploadQueueState.photoConcurrentCount {
                var userInfo: [AnyHashable: Any] = [MEGAPhotoConcurrentCountUserInfoKey: uploadQueueState.photoConcurrentCount]
                if let pausedReason = uploadQueueState.photoPausedReason {
                    userInfo[MEGACameraUploadsPhotosPausedReasonUserInfoKey] = pausedReason
                }
                NotificationCenter.default.post(
                    name: .MEGACameraUploadPhotoConcurrentCountChanged,
                    object: self,
                    userInfo: userInfo)
            }
            
            if currentUploadQueueStates.videoConcurrentCount != uploadQueueState.videoConcurrentCount {
                var userInfo: [AnyHashable: Any] = [MEGAVideoConcurrentCountUserInfoKey: uploadQueueState.videoConcurrentCount]
                if let pausedReason = uploadQueueState.videoPausedReason {
                    userInfo[MEGACameraUploadsVideosPausedReasonUserInfoKey] = pausedReason
                }
                NotificationCenter.default.post(
                    name: .MEGACameraUploadVideoConcurrentCountChanged,
                    object: self,
                    userInfo: userInfo)
            }
            
            currentUploadQueueStates = uploadQueueState
        }
    }
    
    // MARK: - Concurrent count calculation
    
    @MainActor
    @objc func calculatePhotoUploadConcurrentCount() -> Int {
        currentUploadQueueStates = calculateCameraUploadQueueStates()
        return currentUploadQueueStates.photoConcurrentCount
    }
    
    @MainActor
    @objc func calculateVideoUploadConcurrentCount() -> Int {
        currentUploadQueueStates = calculateCameraUploadQueueStates()
        return currentUploadQueueStates.videoConcurrentCount
    }
    
    func photoQueuePausedReason() -> CameraUploadMediaTypePausedReason? {
        currentUploadQueueStates.photoPausedReason
    }
    
    func videoQueuePausedReason() -> CameraUploadMediaTypePausedReason? {
        currentUploadQueueStates.videoPausedReason
    }
    
    @MainActor
    private func calculateCameraUploadQueueStates() -> CameraUploadQueueStates {
        let statuses = [
            queueStatusByApplicationState(UIApplication.shared.applicationState),
            queueStatusByBatteryState(
                UIDevice.current.batteryState,
                batteryLevel: UIDevice.current.batteryLevel,
                isLowPowerModeEnabled: ProcessInfo.processInfo.isLowPowerModeEnabled),
            queueStatusByThermalState(ProcessInfo.processInfo.thermalState)
        ]
        return CameraUploadQueueStates(
            photoUploadState: statuses.min(by: { $0.photoConcurrentCount < $1.photoConcurrentCount }) ?? .defaultMaximum,
            videoUploadState: statuses.min(by: { $0.videoConcurrentCount < $1.videoConcurrentCount }) ?? .defaultMaximum)
    }
    
    private func queueStatusByApplicationState(_ applicationState: UIApplication.State) -> CameraUploadQueueState {
        if applicationState == .background {
            .background
        } else {
            .defaultMaximum
        }
    }
    
    private func queueStatusByBatteryState(_ batteryState: UIDevice.BatteryState,
                                           batteryLevel: Float,
                                           isLowPowerModeEnabled: Bool
    ) -> CameraUploadQueueState {
        guard !isLowPowerModeEnabled else {
            return .lowPowerMode
        }
        guard batteryState == .unplugged else {
            return .batteryCharging
        }
        return if batteryLevel < 0.15 {
            .batteryLevel(.below15)
        } else if batteryLevel < 0.25 {
            .batteryLevel(.below25)
        } else if batteryLevel < 0.4 {
            .batteryLevel(.below40)
        } else if batteryLevel < 0.55 {
            .batteryLevel(.below55)
        } else if batteryLevel < 0.75 {
            .batteryLevel(.below75)
        } else {
            .batteryLevel(.above75)
        }
    }
    
    private func queueStatusByThermalState(_ thermalState: ProcessInfo.ThermalState) -> CameraUploadQueueState {
        switch thermalState {
        case .critical: .thermalState(.critical)
        case .serious: .thermalState(.serious)
        case .fair: .thermalState(.fair)
        case .nominal: .defaultMaximum
        @unknown default: .defaultMaximum
        }
    }
}

enum CameraUploadQueueState: Sendable, Equatable {
    enum BatteryLevel: Sendable, Equatable {
        case above75
        case below75
        case below55
        case below40
        case below25
        case below15
    }
    enum ThermalState: Sendable, Equatable {
        case fair
        case serious
        case critical
    }
    case background
    case lowPowerMode
    case batteryCharging
    case batteryLevel(BatteryLevel)
    case thermalState(ThermalState)
    case defaultMaximum
}

extension CameraUploadQueueState {
    var photoConcurrentCount: Int {
        switch self {
        case .background, .batteryLevel(.below25): 1
        case .lowPowerMode, .batteryLevel(.below40): 2
        case .batteryLevel(.below55), .thermalState(.fair): 3
        case .batteryCharging, .batteryLevel(.above75), .batteryLevel(.below75), .defaultMaximum: 4
        case .batteryLevel(.below15), .thermalState(.critical): 0
        case .thermalState(.serious): 1
        }
    }
    
    var photoPausedReason: CameraUploadMediaTypePausedReason? {
        switch self {
        case .batteryLevel(.below15): .lowBattery
        case .thermalState(.critical): .thermalState(.critical)
        default: nil
        }
    }
    
    var videoConcurrentCount: Int {
        switch self {
        case .background, .lowPowerMode, .batteryCharging, .batteryLevel(.above75), .batteryLevel(.below75), .batteryLevel(.below55), .batteryLevel(.below40), .batteryLevel(.below25), .thermalState(.fair), .defaultMaximum: 1
        case .batteryLevel(.below15), .thermalState(.serious), .thermalState(.critical): 0
        }
    }
    
    var videoPausedReason: CameraUploadMediaTypePausedReason? {
        switch self {
        case .batteryLevel(.below15): .lowBattery
        case .thermalState(.serious): .thermalState(.serious)
        case .thermalState(.critical): .thermalState(.critical)
        default: nil
        }
    }
}

private struct CameraUploadQueueStates {
    let photoUploadState: CameraUploadQueueState
    let videoUploadState: CameraUploadQueueState
}

extension CameraUploadQueueStates {
    var photoConcurrentCount: Int {
        photoUploadState.photoConcurrentCount
    }
    
    var photoPausedReason: CameraUploadMediaTypePausedReason? {
        photoUploadState.photoPausedReason
    }
    
    var videoConcurrentCount: Int {
        photoUploadState.videoConcurrentCount
    }
    
    var videoPausedReason: CameraUploadMediaTypePausedReason? {
        photoUploadState.videoPausedReason
    }
}
