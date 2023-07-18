import Combine
import SwiftUI

final class ExclusionStore: ObservableObject {
    @Published var isScrolling = false
    // When the Runloop is in the default (kCFRunLoopDefaultMode) mode, a time signal will be sent every 0.1 seconds.
    private let idlePublisher = Timer.publish(every: 0.1, on: .main, in: .default).autoconnect()
    // When the Runloop is in the tracking (UITrackingRunLoopMode) mode, a time signal will be sent every 0.1 seconds.
    private let scrollingPublisher = Timer.publish(every: 0.1, on: .main, in: .tracking).autoconnect()
    
    private var subscriptions = Set<AnyCancellable>()
    
    init() {
        scrollingPublisher
            .map { _ in 1 } // Send 1 when scrolling
            .merge(with:
                    idlePublisher
                .map { _ in 0 } // Send 0 when not scrolling
            )
            .receive(on: DispatchQueue.main)
            .sink { [weak self] output in
                guard let self else { return }
                if output == 1, !isScrolling {
                    isScrolling = true
                }
                if output == 0, self.isScrolling {
                    isScrolling = false
                }
            }
            .store(in: &subscriptions)
    }
}

struct ScrollStatusMonitorModifier: ViewModifier {
    @StateObject private var store = ExclusionStore()
    @Binding var isScrolling: Bool
    func body(content: Content) -> some View {
        content
            .onChange(of: store.isScrolling) { value in
                isScrolling = value
            }
    }
}

public extension View {
    func scrollStatusMonitor(_ isScrolling: Binding<Bool>) -> some View {
        modifier(ScrollStatusMonitorModifier(isScrolling: isScrolling))
    }
}
