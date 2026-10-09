import Combine
import MEGAAppPresentation
import MEGAL10n
import MEGASwiftUI

@MainActor
final class LeftOffItemsOfflineNodeTapGate: ObservableObject {
    @Published var snackBar: SnackBar?

    private let dispatcher: OfflineAwareNodeTapDispatcher

    init(dispatcher: OfflineAwareNodeTapDispatcher) {
        self.dispatcher = dispatcher
        dispatcher.showFileUnavailableSnackBar = { [weak self] in
            self?.snackBar = SnackBar(message: Strings.Localizable.CloudDrive.Offline.fileNotAvailableOffline)
        }
    }

    func handler(wrapping handler: any NodeSelectionHandling) -> some NodeSelectionHandling {
        OfflineAwareNodeSelectionHandler(wrapping: handler, tapDispatcher: dispatcher)
    }
}
