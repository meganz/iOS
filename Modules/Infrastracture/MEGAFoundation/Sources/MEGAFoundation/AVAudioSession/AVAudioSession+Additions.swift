import AVFoundation

/// iOS 27 reports a synchronous `setActive` on the main thread as a hang risk and adds the non-blocking
/// `activate(options:completionHandler:)` / `deactivate(options:completionHandler:)`.
/// These wrappers use them on iOS 27+ and keep the synchronous `setActive` on earlier versions, whose behaviour is unchanged.
public extension AVAudioSession {
    func activateWithoutBlocking(options: AVAudioSessionActivationOptions = [], completion: (@Sendable ((any Error)?) -> Void)? = nil) {
        // The iOS 27 SDK (Xcode 27, Swift 6.4) is needed to build the non-blocking call
        #if compiler(>=6.4)
        if #available(iOS 27.0, *) {
            activate(options: options) { _, error in completion?(error) }
            return
        }
        #endif
        do {
            try setActive(true)
            completion?(nil)
        } catch {
            completion?(error)
        }
    }

    /// `options` is `SetActiveOptions` because `AVAudioSessionDeactivationOptions.notifyOthersOnDeactivation` is only available on iOS 27+.
    func deactivateWithoutBlocking(options: SetActiveOptions = [], completion: (@Sendable ((any Error)?) -> Void)? = nil) {
        // The iOS 27 SDK (Xcode 27, Swift 6.4) is needed to build the non-blocking call
        #if compiler(>=6.4)
        if #available(iOS 27.0, *) {
            let deactivationOptions: AVAudioSessionDeactivationOptions = options.contains(.notifyOthersOnDeactivation) ? .notifyOthersOnDeactivation : []
            deactivate(options: deactivationOptions) { _, error in completion?(error) }
            return
        }
        #endif
        do {
            try setActive(false, options: options)
            completion?(nil)
        } catch {
            completion?(error)
        }
    }
}

@objc public extension AVAudioSession {
    var isBluetoothAudioRouteAvailable: Bool {
        guard let availableInputs = self.availableInputs else {
            return false
        }

        let bluetoothPorts: Set<AVAudioSession.Port> = [.bluetoothA2DP, .bluetoothLE, .bluetoothHFP]

        return availableInputs.contains { bluetoothPorts.contains($0.portType) }
    }

    func isOutputEqualToPortType(_ portType: AVAudioSession.Port) -> Bool {
        currentRoute.outputs.first?.portType == portType
    }
}
