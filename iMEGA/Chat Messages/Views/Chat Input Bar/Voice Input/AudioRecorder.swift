import MEGADomain

class AudioRecorder: NSObject {

    enum RecordError: Error {
        case activeCall
        case recorderInstanceDoesNotExist
        case notCurrentlyRecording
        case notConfigured
    }
    
    private var recorder: AVAudioRecorder?
    private var displayLink: CADisplayLink!
    private var recordStartDate: Date!
    private var meterTable = MeterTable()
    private var isConfigured = false

    private var isCallActive: Bool {
        return MEGAChatSdk.shared.mnz_existsActiveCall
    }
    
    private var destinationURL: URL {
        let filename = String(format: "%@.%@", (Date() as NSDate).mnz_formattedDefaultNameForMedia(), "m4a")
        let destinationPath = NSTemporaryDirectory().append(pathComponent: filename)
        return URL(fileURLWithPath: destinationPath)
    }
    
    private var recorderSettings: [String: Any] {
        return [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 16000,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
    }
    
    var updateHandler: ((String, Int) -> Void)?
    var isRecording: Bool {
        return recorder?.isRecording ?? false
    }
    
    @MainActor
    func configureForRecording() {
        let isPlayerAlive = AudioPlayerManager.shared.isPlayerAlive()
        if isPlayerAlive {
            AudioPlayerManager.shared.audioInterruptionDidStart()
        }
        AudioSessionUseCase.default.configureAudioRecorderAudioSession(isPlayerAlive: isPlayerAlive)
        
        isConfigured = true
    }

    func start() throws -> Bool {
        guard !isCallActive else {
            UINotificationFeedbackGenerator().notificationOccurred(.error)
            throw RecordError.activeCall
        }
        
        guard isConfigured else {
            UINotificationFeedbackGenerator().notificationOccurred(.error)
            throw RecordError.notConfigured
        }
        
        if !FileManager.default.fileExists(atPath: NSTemporaryDirectory()) {
            try FileManager.default.createDirectory(atPath: NSTemporaryDirectory(),
                                                    withIntermediateDirectories: true,
                                                    attributes: nil)
        }

        recorder = try AVAudioRecorder(url: destinationURL, settings: recorderSettings)
        
        guard let recorder = recorder else {
            UINotificationFeedbackGenerator().notificationOccurred(.error)
            throw RecordError.recorderInstanceDoesNotExist
        }
        
        recorder.isMeteringEnabled = true
        
        if recorder.record() {
            recordStartDate = Date()
            displayLink = CADisplayLink(target: self, selector: #selector(update))
            displayLink.preferredFramesPerSecond = 60
            displayLink.add(to: .current, forMode: .common)
            return true
        }
        
        return false
    }
    
    func stopRecording() throws -> String {
        guard let recorder = recorder else {
            UINotificationFeedbackGenerator().notificationOccurred(.error)
            throw RecordError.recorderInstanceDoesNotExist
        }
        
        guard recorder.isRecording else {
            throw RecordError.notCurrentlyRecording
        }
        
        recorder.stop()
        displayLink?.invalidate()
        displayLink = nil
        
        Task {
            await self.finalizeAfterStopRecording()
        }

        return recorder.url.path
    }
    
    @MainActor
    private func finalizeAfterStopRecording() {
        if AudioPlayerManager.shared.isPlayerAlive() {
            AudioPlayerManager.shared.audioInterruptionDidEndNeedToResume(true)
        } else {
            do {
                try AVAudioSession.sharedInstance().setMode(.voiceChat)
                try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
            } catch {
                MEGALogError("[AudioRecorder] AVAudioSession cleanup error: \(error.localizedDescription)")
            }
        }
    }
    
    @objc func update() {
        guard let handler = updateHandler,
            let recorder = recorder else {
                return
        }
        
        let timeDifference = Date().timeIntervalSince1970 - recordStartDate.timeIntervalSince1970
        let timeString = timeDifference.timeString
        
        recorder.updateMeters()
        let decibels = recorder.averagePower(forChannel: 0)
        let normalizedValue: Float = min((meterTable[decibels] * 100.0) + 1, 100)

        handler(timeString, Int(normalizedValue))
    }
    
}
