import MEGAL10n

extension SimpleDialogView {
    static func upgradePlanDialog(upgradeAction: @escaping () -> Void) -> SimpleDialogView {
        SimpleDialogView(
            dialogConfig:
                SimpleDialogConfig(
                    imageResource: .upgradeToProPlan,
                    title: Strings.Localizable.Calls.FreePlanLimitWarning.UpgradeToProDialog.title,
                    message: Strings.Localizable.Calls.FreePlanLimitWarning.UpgradeToProDialog.message,
                    buttonTitle: Strings.Localizable.Calls.FreePlanLimitWarning.UpgradeToProDialog.button,
                    buttonAction: upgradeAction
                )
        )
    }
}
