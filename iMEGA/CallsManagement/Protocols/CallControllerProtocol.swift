import CoreTelephony
import MEGADomain

/// `CallControllerProtocol` defines the entry points for managing call actions triggered by user, such as starting, muting, or ending a call.
/// This protocol acts as an abstraction layer for systems responsible for handling call-related operations.
/// It can be implemented by frameworks like CallKit or by custom in-app call management systems (e.g., MEGA app).
protocol CallControllerProtocol: AnyObject {
    /// Configures the calls coordinator with necessary information to handle incoming and outgoing calls.
    ///
    /// This function is typically called by the framework or system implementing this protocol
    /// to initialize its internal state and prepare for call management.
    ///
    /// - Parameter callsCoordinator: The coordinator instance that will be used to handle calls.
    func configureCallsCoordinator(_ callsCoordinator: CallsCoordinator)
    
    /// Starts a new call with the specified action sync.
    ///
    /// This function is responsible for handling user action to start an outgoing call
    /// and setting up the call's state based on the provided `CallActionSync`.
    ///
    /// - Parameter actionSync: The synchronization object that contains the necessary information to manage the call's state.
    func startCall(with actionSync: CallActionSync)
    
    /// Answers an incoming/ongoing call in the specified chat room.
    ///
    /// This function is responsible for handling user action to accept an incoming or joining an ongoing call
    /// and updating the call's state.
    ///
    /// - Parameters:
    ///   - chatRoom: The chat room holding the call.
    ///   - uuid: The unique identifier for the call, which can be used to identify and manage the state.
    func answerCall(in chatRoom: ChatRoomEntity, withUUID uuid: UUID)
    
    /// Ends an ongoing call in the specified chat room.
    ///
    /// This function is responsible for handling user action to end call
    /// and updating the call's state.
    ///
    /// - Parameters:
    ///   - chatRoom: The chat room holding the call.
    ///   - endForAll: A boolean flag indicating whether the call should be ended for all participants or just leave it.
    func endCall(in chatRoom: ChatRoomEntity, endForAll: Bool)
    
    /// Mutes or unmutes the call in the specified chat room.
    ///
    /// This function is responsible for handling user action to mute or unmute call
    /// and updating the call's state.
    ///
    /// - Parameters:
    ///   - chatRoom: The chat room holding the call.
    ///   - muted: A boolean flag indicating whether the call should be muted or unmuted.
    func muteCall(in chatRoom: ChatRoomEntity, muted: Bool)
}

struct CallControllerProvider {
    func provideCallController() -> any CallControllerProtocol {
        if isCallKitAvailable() {
            CallKitCallController.shared
        } else {
            MEGACallController.shared
        }
    }
    
    func isCallKitAvailable() -> Bool {
#if targetEnvironment(simulator)
        return false
#else
        // Check if the device supports telephony (some iPads doesn't)
        let telephonyInfo = CTTelephonyNetworkInfo()
        let supportsTelephony = telephonyInfo.serviceSubscriberCellularProviders?.isEmpty == false
        return supportsTelephony
#endif
    }
}
