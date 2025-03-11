extension LTHPasscodeViewController {
    @objc open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        lockToPortraitIfPhone()
    }

    @objc open override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        resetOrientationIfPhone()
    }

    private func lockToPortraitIfPhone() {
        guard !UIDevice.current.iPadDevice else { return }

        appDelegate?.lockOrientation(.portrait, in: self)
    }

    private func resetOrientationIfPhone() {
        guard !UIDevice.current.iPadDevice else { return }

        appDelegate?.resetSupportedInterfaceOrientation(in: self)
    }

    private var appDelegate: AppDelegate? {
        UIApplication.shared.delegate as? AppDelegate
    }
}
