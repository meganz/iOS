

class AudioRecorder: NSObject {

    enum RecordError: Error {
        case activeCall
        case recorderInstanceDoesNotExist
    }
    
    private var recorder: AVAudioRecorder?
    private var displayLink: CADisplayLink?
    private var recordStartDate: Date!
    private var meterTable = MeterTable()

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

        return recorder.url.path
    }
    
    @objc func update() {
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
        let normalizedValue: Float = min((meterTable[decibels] * 100.0) + 1, 100)
        handler(timeString, Int(normalizedValue))
    }
}
