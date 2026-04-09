import SwiftUI
import UIKit

@MainActor
public struct TransferIndicatorToolbarFactory {
    public enum NavigationPlacement {
        case leading
        case trailing
    }

    private static let observers = NSMapTable<UIViewController, BarItemObserver>.weakToStrongObjects()

    public let isEnabled: Bool
    private let action: (() -> Void)?

    public init(
        isEnabled: Bool,
        action: (() -> Void)? = nil
    ) {
        self.isEnabled = isEnabled
        self.action = action
    }

    public static func placement(forTrailingItemCount trailingItemCount: Int) -> NavigationPlacement {
        trailingItemCount >= 2 ? .leading : .trailing
    }

    @ViewBuilder
    public var content: some View {
        if isEnabled {
            TransferIndicatorView(action: action)
        }
    }

    @ToolbarContentBuilder
    public func toolbarContent(trailingItemCount: Int) -> some ToolbarContent {
        if isEnabled {
            ToolbarItem(
                placement: Self.placement(forTrailingItemCount: trailingItemCount) == .leading
                    ? .topBarLeading : .topBarTrailing
            ) {
                TransferIndicatorView(action: action)
            }
        }
    }

    public func injectIfNeeded(into viewController: UIViewController) {
        guard SharedTransferIndicator.isConfigured else { return }

        let placement = Self.placement(forTrailingItemCount: viewController.navigationItem.rightBarButtonItems?.count ?? 0)

        if let existing = Self.observers.object(forKey: viewController) {
            existing.update(factory: self, placement: placement)
            return
        }

        let observer = BarItemObserver(
            viewController: viewController,
            factory: self,
            placement: placement
        )
        Self.observers.setObject(observer, forKey: viewController)
        observer.sync()
    }

    public static var hidden: Self {
        Self(isEnabled: false)
    }

    public static func indicator(action: (() -> Void)? = nil) -> Self {
        Self(isEnabled: true, action: action)
    }

    private func makeBarButtonItem() -> UIBarButtonItem {
        let hostingController = UIHostingController(rootView: TransferIndicatorView(action: action))
        hostingController.view.backgroundColor = .clear
        hostingController.view.sizeToFit()
        return UIBarButtonItem(customView: hostingController.view)
    }
}

extension TransferIndicatorToolbarFactory {
    @MainActor
    private final class BarItemObserver {
        private weak var viewController: UIViewController?
        private var factory: TransferIndicatorToolbarFactory
        private var placement: NavigationPlacement
        private var barItem: UIBarButtonItem?
        private var monitorTask: Task<Void, Never>?

        init(
            viewController: UIViewController,
            factory: TransferIndicatorToolbarFactory,
            placement: NavigationPlacement
        ) {
            self.viewController = viewController
            self.factory = factory
            self.placement = placement

            guard let publisher = SharedTransferIndicator.isVisiblePublisher else { return }
            monitorTask = Task { [weak self] in
                for await isVisible in publisher.values {
                    guard !Task.isCancelled else { return }
                    if isVisible {
                        self?.insert()
                    } else {
                        self?.remove()
                    }
                }
            }
        }

        deinit {
            monitorTask?.cancel()
        }

        func update(factory: TransferIndicatorToolbarFactory, placement: NavigationPlacement) {
            remove()
            self.factory = factory
            self.placement = placement
            sync()
        }

        func sync() {
            guard factory.isEnabled, SharedTransferIndicator.isCurrentlyVisible else {
                remove()
                return
            }
            insert()
        }

        private func insert() {
            guard factory.isEnabled, let vc = viewController else { return }
            remove()

            let barItem = factory.makeBarButtonItem()
            self.barItem = barItem

            switch placement {
            case .trailing:
                var items = vc.navigationItem.rightBarButtonItems ?? []
                items.append(barItem)
                vc.navigationItem.rightBarButtonItems = items
            case .leading:
                var items = vc.navigationItem.leftBarButtonItems ?? []
                items.append(barItem)
                vc.navigationItem.leftBarButtonItems = items
            }
        }

        private func remove() {
            guard let vc = viewController, let barItem else { return }

            var leftItems = vc.navigationItem.leftBarButtonItems ?? []
            leftItems.removeAll { $0 === barItem }
            vc.navigationItem.leftBarButtonItems = leftItems.isEmpty ? nil : leftItems

            var rightItems = vc.navigationItem.rightBarButtonItems ?? []
            rightItems.removeAll { $0 === barItem }
            vc.navigationItem.rightBarButtonItems = rightItems.isEmpty ? nil : rightItems

            self.barItem = nil
        }
    }
}
