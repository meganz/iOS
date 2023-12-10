extension UIActivityIndicatorView {
    
    @objc class func mnz_init() -> UIActivityIndicatorView {
        var activityIndicatorView: UIActivityIndicatorView
        
        activityIndicatorView = UIActivityIndicatorView.init(style: .medium)
        activityIndicatorView.color = (activityIndicatorView.traitCollection.userInterfaceStyle == UIUserInterfaceStyle.dark) ? MEGAAppColor.White._FFFFFF.uiColor : UIColor.mnz_primaryGray(for: activityIndicatorView.traitCollection)
        
        return activityIndicatorView
    }
}
