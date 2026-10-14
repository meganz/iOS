@MainActor
final class PDFViewerLifecycleTracking {
    private let trackingUseCase: any PDFViewerTrackingUseCaseProtocol
    private let onViewerPresented: @MainActor () -> Void
    private var didPresent = false
    private var didClose = false

    init(
        trackingUseCase: some PDFViewerTrackingUseCaseProtocol,
        onViewerPresented: @escaping @MainActor () -> Void
    ) {
        self.trackingUseCase = trackingUseCase
        self.onViewerPresented = onViewerPresented
    }

    func viewerDidAppear() {
        guard !didPresent, !didClose else { return }
        didPresent = true
        trackingUseCase.track(.screenPresented)
        onViewerPresented()
    }

    func viewerDidClose() {
        guard didPresent, !didClose else { return }
        didClose = true
        trackingUseCase.track(.closed)
    }
}
