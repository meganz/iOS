extension UIApplication {
    static func present(_ modal: PermissionsModalModel) {
        mnz_presentingViewController().present(modal.viewController, animated: true)
    }
}
