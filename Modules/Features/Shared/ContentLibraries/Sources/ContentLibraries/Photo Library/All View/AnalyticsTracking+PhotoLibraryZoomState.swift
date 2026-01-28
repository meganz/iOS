import MEGAAnalyticsiOS
import MEGAAppPresentation

extension AnalyticsTracking {
    func trackZoomStateChange(_ state: PhotoLibraryZoomState) {
        let event: (any EventIdentifier)? = switch state.scaleFactor {
        case .one: MediaScreenGridSizeLargeSelectedEvent()
        case .three: MediaScreenGridSizeDefaultSelectedEvent()
        case .five: MediaScreenGridSizeCompactSelectedEvent()
        default: nil
        }
        guard let event else { return }
        
        trackAnalyticsEvent(with: event)
    }
}
