import Foundation

extension CameraUploadsTableViewController {
    @objc func didToggleCameraUploads(_ enabled: Bool) {
        let eventDetails = AnalayticsEventEntity.cameraUploadsSettings(enabled: enabled)
        let analyticsUseCase = AnalyticsUseCase(repository: GoogleAnalyticsRepository())
        analyticsUseCase.logEvent(eventDetails.name, parameters: eventDetails.parameters)
    }
}
