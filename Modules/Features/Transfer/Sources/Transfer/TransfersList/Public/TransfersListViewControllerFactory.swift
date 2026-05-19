import SwiftUI
import UIKit

@MainActor
public enum TransfersListViewControllerFactory {
    public static func make() -> UIViewController {
        let host = UIHostingController(rootView: TransfersListView())
        host.hidesBottomBarWhenPushed = true
        return host
    }
}
