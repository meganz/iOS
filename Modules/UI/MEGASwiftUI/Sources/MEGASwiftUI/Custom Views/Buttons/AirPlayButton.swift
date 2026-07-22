import AVKit
import SwiftUI

public struct AirPlayButton: UIViewRepresentable {
    private let backgroundColor: UIColor
    private let tintColor: UIColor
    private let activeTintColor: UIColor
    private let onWillBeginPresentingRoutes: (() -> Void)?
    private let onDidEndPresentingRoutes: (() -> Void)?

    public init(
        backgroundColor: UIColor = .clear,
        tintColor: UIColor = .clear,
        activeTintColor: UIColor = .clear,
        onWillBeginPresentingRoutes: (() -> Void)? = nil,
        onDidEndPresentingRoutes: (() -> Void)? = nil
    ) {
        self.backgroundColor = backgroundColor
        self.tintColor = tintColor
        self.activeTintColor = activeTintColor
        self.onWillBeginPresentingRoutes = onWillBeginPresentingRoutes
        self.onDidEndPresentingRoutes = onDidEndPresentingRoutes
    }

    public func makeUIView(context: Context) -> AVRoutePickerView {
        let routePickerView = AVRoutePickerView()
        routePickerView.backgroundColor = backgroundColor
        routePickerView.tintColor = tintColor
        routePickerView.activeTintColor = activeTintColor
        routePickerView.delegate = context.coordinator
        return routePickerView
    }

    public func updateUIView(_ uiView: AVRoutePickerView, context: Context) {
        context.coordinator.onWillBeginPresentingRoutes = onWillBeginPresentingRoutes
        context.coordinator.onDidEndPresentingRoutes = onDidEndPresentingRoutes
    }

    public func makeCoordinator() -> Coordinator {
        Coordinator(
            onWillBeginPresentingRoutes: onWillBeginPresentingRoutes,
            onDidEndPresentingRoutes: onDidEndPresentingRoutes
        )
    }

    public final class Coordinator: NSObject, AVRoutePickerViewDelegate {
        var onWillBeginPresentingRoutes: (() -> Void)?
        var onDidEndPresentingRoutes: (() -> Void)?

        init(
            onWillBeginPresentingRoutes: (() -> Void)?,
            onDidEndPresentingRoutes: (() -> Void)?
        ) {
            self.onWillBeginPresentingRoutes = onWillBeginPresentingRoutes
            self.onDidEndPresentingRoutes = onDidEndPresentingRoutes
        }

        public func routePickerViewWillBeginPresentingRoutes(_ routePickerView: AVRoutePickerView) {
            onWillBeginPresentingRoutes?()
        }

        public func routePickerViewDidEndPresentingRoutes(_ routePickerView: AVRoutePickerView) {
            onDidEndPresentingRoutes?()
        }
    }
}
