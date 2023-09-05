import AVFoundation

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
