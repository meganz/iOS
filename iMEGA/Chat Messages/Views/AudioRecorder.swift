

class AudioRecorder {

    enum RecordError: Error {
        case activeCall
        case recorderInstanceDoesNotExist
    }
    
    private var recorder: AVAudioRecorder?
    private var displayLink: CADisplayLink?
    private var recordStartDate: Date!

    private var isCallActive: Bool {
        return MEGASdkManager.sharedMEGAChatSdk()!.mnz_existsActiveCall
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
    
    func start() throws -> Bool {
        guard !isCallActive else {
            UINotificationFeedbackGenerator().notificationOccurred(.error)
            throw RecordError.activeCall
        }
        
        try AVAudioSession.sharedInstance().setMode(.default)
        try AVAudioSession.sharedInstance().setActive(true)
        
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
            let displayLink = CADisplayLink(target: self, selector: #selector(update))
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
        
        recorder.stop()
        
        try AVAudioSession.sharedInstance().setMode(.voiceChat)
        try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)

        UINotificationFeedbackGenerator().notificationOccurred(.success)
        return recorder.url.path
    }
    
    @objc func update() {
        
        var normalizedValue: Float = 0.0

        guard let handler = updateHandler else {
            return
        }
        
        guard let recorder = recorder else {
            fatalError("AudioRecorder: recorder cannot be nil")
        }
        
        let timeDifference = Date().timeIntervalSince1970 - recordStartDate.timeIntervalSince1970
        let timeString = NSString.mnz_string(fromTimeInterval: timeDifference)
        
        recorder.updateMeters()
        let decibels = recorder.averagePower(forChannel: 0)
        normalizedValue = min(normalizedPower(decibels) * 100 + 1, 100)

        handler(timeString, Int(normalizedValue))
    }
    
    func normalizedPower(_ decibels: Float) -> Float {
        if (decibels < -60.0 || decibels == 0.0) {
            return 0.0
        }
        let temp = (pow(10.0, 0.05 * decibels) - pow(10.0, 0.05 * -60.0))
        return max(0, powf(temp * (1.0 / (1.0 - pow(10.0, 0.05 * -60.0))), 1.0 / 2.0))
    }
    
}
