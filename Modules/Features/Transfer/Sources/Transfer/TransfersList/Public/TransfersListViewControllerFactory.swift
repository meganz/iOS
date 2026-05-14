import SwiftUI
import UIKit

@MainActor
public enum TransfersListViewControllerFactory {
    public static func make() -> UIViewController {
        UIHostingController(rootView: TransfersListView())
    }
}
