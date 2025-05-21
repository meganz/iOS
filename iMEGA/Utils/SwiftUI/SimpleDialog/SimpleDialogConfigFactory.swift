import MEGAAssets
import MEGAL10n
import SwiftUI

struct SimpleDialogConfigFactory {
    static func upgradePlanDialog(
        upgradeAction: @escaping () -> Void,
        dismissAction: @escaping () -> Void
    ) -> SimpleDialogConfig {
        .init(
            image: MEGAAssets.Image.upgradeToProPlan,
            title: Strings.Localizable.Calls.FreePlanLimitWarning.UpgradeToProDialog.title,
            message: Strings.Localizable.Calls.FreePlanLimitWarning.UpgradeToProDialog.message,
            buttons: [
                .init(
                    title: Strings.Localizable.Calls.FreePlanLimitWarning.UpgradeToProDialog.button,
                    theme: .primary,
                    action: .action({ _ in upgradeAction() })
                )
            ],
            dismissAction: dismissAction
        )
    }
    
    static func shareLinkDialog(
        sendAction: @escaping AsyncViewAction,
        shareAction: @escaping AsyncViewAction,
        dismissAction: @escaping () -> Void
    ) -> SimpleDialogConfig {
        .init(
            image: MEGAAssets.Image.shareLink,
            title: Strings.Localizable.Chat.Meetings.ShareLink.main,
            titleStyle: .large,
            message: Strings.Localizable.Chat.Meetings.ShareLink.description,
            buttons: [
                .init(
                    title: Strings.Localizable.Chat.Meetings.ShareLink.sendToChat,
                    theme: .secondary,
                    action: .asyncAction(sendAction)
                ),
                .init(
                    title: Strings.Localizable.Chat.Meetings.ShareLink.shareLink,
                    theme: .primary,
                    action: .asyncAction(shareAction)
                )
            ],
            dismissAction: dismissAction
        )
    }
}
