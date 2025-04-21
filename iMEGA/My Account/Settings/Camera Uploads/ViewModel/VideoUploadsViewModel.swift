import MEGAAnalyticsiOS
import MEGAAppPresentation

enum VideoUploadsEvents {
    case videoUploads(Bool)
    case videoCodec(VideoCodec)
    case videoQuality(VideoQuality)
}

enum VideoCodec: Int {
    case HEVC, H264
}

enum VideoQuality: Int {
    case low = 0, medium, high, original
}

final class VideoUploadsViewModel: NSObject {
    private let tracker: any AnalyticsTracking
    
    init(tracker: some AnalyticsTracking = DIContainer.tracker) {
        self.tracker = tracker
    }
    
    func trackEvent(_ event: VideoUploadsEvents) {
        switch event {
        case .videoUploads(let enabled):
            tracker.trackAnalyticsEvent(
                with: enabled ? VideoUploadsEnabledEvent() : VideoUploadsDisabledEvent()
            )
        case .videoCodec(let codec):
            switch codec {
            case .HEVC:
                tracker.trackAnalyticsEvent(with: VideoCodecHEVCSelectedEvent())
            case .H264:
                tracker.trackAnalyticsEvent(with: VideoCodecH264SelectedEvent())
            }
        case .videoQuality(let quality):
            switch quality {
            case .low:
                tracker.trackAnalyticsEvent(with: VideoQualityLowEvent())
            case .medium:
                tracker.trackAnalyticsEvent(with: VideoQualityMediumEvent())
            case .high:
                tracker.trackAnalyticsEvent(with: VideoQualityHighEvent())
            case .original:
                tracker.trackAnalyticsEvent(with: VideoQualityOriginalEvent())
            }
        }
    }
}
