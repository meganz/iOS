import Combine
import MEGAAppPresentation
import MEGAL10n
import MEGASwiftUI

/// One Home screen's gate for a tap on a node that would need downloading while offline, together
/// with the snack bar it reports through (IOS-12409)
///
/// An `ObservableObject` because the screen observes the snack bar it publishes. Holding the state
/// in an object also means the dispatcher can be pointed at it in `init`
@MainActor
final class HomeOfflineNodeTapGate: ObservableObject {
    static var fileUnavailableOfflineSnackBar: SnackBar {
        SnackBar(message: Strings.Localizable.CloudDrive.Offline.fileNotAvailableOffline)
    }

    @Published var snackBar: SnackBar?

    private let dispatcher: OfflineAwareNodeTapDispatcher

    init(dispatcher: OfflineAwareNodeTapDispatcher) {
        self.dispatcher = dispatcher
        dispatcher.showFileUnavailableSnackBar = { [weak self] in
            self?.snackBar = Self.fileUnavailableOfflineSnackBar
        }
    }

    func handler(wrapping handler: any NodeSelectionHandling) -> some NodeSelectionHandling {
        OfflineAwareNodeSelectionHandler(wrapping: handler, tapDispatcher: dispatcher)
    }
}
