public extension SVProgressHUD {
    static func configureHudDarkMode() {
        SVProgressHUD.setHudViewCustomBlurEffect(UIBlurEffect.init(style: UIBlurEffect.Style.systemMaterialDark))
        SVProgressHUD.setForegroundColor(MEGAAppColor.White._FFFFFF.uiColor)
        SVProgressHUD.setForegroundImageColor(MEGAAppColor.White._FFFFFF.uiColor)
    }
}
