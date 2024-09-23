extension UIActivityIndicatorView {
    
    @objc class func mnz_init() -> UIActivityIndicatorView {
        var activityIndicatorView: UIActivityIndicatorView
        
        activityIndicatorView = UIActivityIndicatorView.init(style: .medium)
        activityIndicatorView.color = (activityIndicatorView.traitCollection.userInterfaceStyle == UIUserInterfaceStyle.dark) ? UIColor.whiteFFFFFF : UIColor.mnz_primaryGray()
        
        return activityIndicatorView
    }
}
