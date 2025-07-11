import MEGADomain

/// `CallsCoordinatorProtocol` defines methods to coordinate call actions between the `CallControllerProtocol`
/// and the MEGA system, ensuring proper integration with the ChatSDK for call management.
///
/// The `CallsCoordinatorProtocol` acts as the intermediary that translates and executes call actions
/// (e.g., start, mute, end) triggered by the call controller into appropriate events within the MEGA system.
///
/// Responsibilities:
/// - Handling the execution of call actions initiated by the `CallControllerProtocol`.
/// - Reporting and managing incoming calls triggered by `VoIPPushDelegate`.
/// - CallKit integration, if applicable, by configuring with its provider delegate.
/// - Passcode app management for call actions.
/// -
///
/// This protocol ensures that call events are seamlessly coordinated between the controller layer
/// and the underlying MEGA system, supporting both system-integrated (e.g., CallKit) and in-app call functionalities.
protocol CallsCoordinatorProtocol: AnyObject, Sendable {
    /// Starts a new call based on the provided `CallActionSync`.
    ///
    /// This function is responsible for initiating an outgoing call in `MEGAChatSdk`
    /// based on the provided synchronization object.
    ///
    /// - Parameter callActionSync: The synchronization object that contains the necessary information to manage the call's state.
    ///
    /// - Returns: A boolean value indicating whether the call was started successfully, or an error if any issues occurred during initialization.
    func startCall(_ callActionSync: CallActionSync) async -> Bool
    
    /// Answers an incoming call based on the provided `CallActionSync`.
    ///
    /// This function is responsible for joining an incoming or ongoing call in `MEGAChatSdk`
    /// based on the provided synchronization object.
    ///
    /// - Parameter callActionSync: The synchronization object that contains the necessary information to manage the call's state.
    ///
    /// - Returns: A boolean value indicating whether the call was answered successfully, or an error if any issues occurred during initialization.
    func answerCall(_ callActionSync: CallActionSync) async -> Bool
    
    /// Ends an in progress call based on the provided `CallActionSync`.
    ///
    /// This function is responsible for ending a call in `MEGAChatSdk`
    /// based on the provided synchronization object.
    ///
    /// - Parameter callActionSync: The synchronization object that contains the necessary information to manage the call's state.
    ///
    /// - Returns: A boolean value indicating whether the call was ended successfully, or an error if any issues occur during finalization.

    func endCall(_ callActionSync: CallActionSync) async -> Bool
    
    /// Mutes or unmutes the call based on the provided `CallActionSync`.
    ///
    /// This function is responsible for updating the call mute status in `MEGAChatSdk`
    /// based on the provided synchronization object.
    ///
    /// - Parameter callActionSync: The synchronization object that contains the necessary information to manage the call's state.
    ///
    /// - Returns: A boolean value indicating whether the call was muted or unmuted successfully, or an error if any issues occur during configuration.

    /// Reports an incoming call for the specified chat ID, and notifies completion when done.
    ///
    /// This function is responsible for passing an incoming call event to the MEGA system,
    /// ensuring that the chat room and related data are updated correctly.
    ///
    /// - Parameters:
    ///   - chatId: The unique identifier for the chat room participating in the call.
    ///     A data structure containing relevant information about this specific chat room.
    ///   - completion: A closure that will be executed when the report is complete, allowing the app
    ///                to react accordingly.
    func muteCall(_ callActionSync: CallActionSync) async -> Bool
    
    /// Reports an incoming call for the specified chat ID, and notifies completion to the VoIP delegate when done.
    ///
    /// This function is responsible for triggering a VoIP notification for incoming call to CallKit, and update the UI based on the data provided.
    ///
    /// - Parameters:
    ///   - chatId: The unique identifier for the chat room holding the incoming call.
    ///   - completion: A closure that will be executed when the report is complete, mandatory to avoid system crashes.
    func reportIncomingCall(in chatId: ChatIdEntity, completion: @escaping () -> Void)
    
    /// Configures the WebRTC audio session when a call takes place.
    ///
    /// This function is responsible for setting up the necessary audio session infrastructure to handle and sync state between `WebRTC` and `iOS`
    func configureWebRTCAudioSession()
    
    /// Sets up the provider delegate for integration with CallKit.
    ///
    /// This function is responsible for configuring any necessary data structures or callbacks
    /// to enable seamless interaction with the CallKit framework, ensuring that the app can use this
    /// advanced call management feature effectively.
    func setupProviderDelegate(_ provider: any CallKitProviderDelegateProtocol)
    
    /// Sets or gets the incoming call for an unknown chat.
    ///
    /// This var is used to keep track of any pending or incomplete data associated with an
    /// incoming call, ensuring that the app remains aware of and can react to updates in this context.
    var incomingCallForUnknownChat: IncomingCallForUnknownChat? { get set }
    
    /// Called when the audio session for a call has been activated by the system.
    ///
    /// Use this callback to start or resume audio-related operations, such as unmuting the microphone
    /// and starting audio rendering, once the system audio session is fully active.
    func didActivateCallAudioSession()
    
    /// Called when the audio session for a call has been deactivated by the system.
    ///
    /// Use this callback to pause or stop audio-related operations, such as muting the microphone
    /// and stopping audio rendering, and to clean up any audio resources before the session is fully released.
    func didDeactivateCallAudioSession()
}
