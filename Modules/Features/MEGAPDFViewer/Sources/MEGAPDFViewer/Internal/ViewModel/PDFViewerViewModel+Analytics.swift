import Foundation

extension PDFViewerViewModel.ViewState {
    struct AnalyticsState {
        var reportedLoadAttempt: UUID?
        var didTrackPasswordUnlock = false
        var activeSearchSession: UUID?
        var searchGeneration: UUID?
        var highlightedResult: Int?
    }
}

extension PDFViewerViewModel {
    func searchSessionDidBegin(_ sessionID: UUID) {
        guard state.isReady, analyticsState.activeSearchSession != sessionID else { return }
        analyticsState.activeSearchSession = sessionID
        analyticsState.searchGeneration = nil
        analyticsState.highlightedResult = nil
        dependency.trackingUseCase.track(.searchSessionStarted)
    }

    func searchSessionDidEnd(_ sessionID: UUID) {
        guard analyticsState.activeSearchSession == sessionID else { return }
        analyticsState.activeSearchSession = nil
        analyticsState.searchGeneration = nil
        analyticsState.highlightedResult = nil
    }

    func searchResultDidChange(sessionID: UUID, generationID: UUID, resultID: Int) {
        guard analyticsState.activeSearchSession == sessionID, resultID >= 0 else { return }
        if analyticsState.searchGeneration != generationID {
            analyticsState.searchGeneration = generationID
            analyticsState.highlightedResult = resultID
            return
        }
        guard analyticsState.highlightedResult != resultID else { return }
        analyticsState.highlightedResult = resultID
        dependency.trackingUseCase.track(.searchResultItemSelected)
    }

    func reportLoadOutcome(_ event: PDFViewerAnalyticsEvent) {
        guard let activeLoadAttempt,
              analyticsState.reportedLoadAttempt != activeLoadAttempt else { return }
        analyticsState.reportedLoadAttempt = activeLoadAttempt
        dependency.trackingUseCase.track(event)
    }

    func reportLoadFailure(_ reason: ViewState.FailureReason) {
        let analyticsFailure: PDFViewerAnalyticsFailure = switch reason {
        case .downloadFailed: .downloadFailed
        case .documentUnreadable: .documentUnreadable
        }
        reportLoadOutcome(.loadFailed(analyticsFailure))
    }

    func trackPasswordUnlockIfNeeded() {
        guard !analyticsState.didTrackPasswordUnlock else { return }
        analyticsState.didTrackPasswordUnlock = true
        dependency.trackingUseCase.track(.passwordUnlocked)
    }
}
