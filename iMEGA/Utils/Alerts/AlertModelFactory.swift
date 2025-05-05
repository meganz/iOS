import Foundation
import MEGAAppPresentation
import MEGAL10n

final class AlertModelFactory {
    private init() { }

    /// Creates an AlertModel to notify the user that a file has been taken down.
    static func makeTakenDownModel(disputeURL: String = MEGADisputeURL) -> AlertModel {
        .init(
            title: nil,
            message: Strings.Localizable.thisFileHasBeenTheSubjectOfATakedownNotice,
            actions: [
                .init(
                    title: Strings.Localizable.disputeTakedown,
                    style: .default,
                    handler: {
                        NSURL(string: disputeURL)?.mnz_presentSafariViewController()
                    }
                ),
                .init(
                    title: Strings.Localizable.cancel,
                    style: .cancel,
                    handler: {}
                )
            ]
        )
    }
}
