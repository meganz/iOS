
extension UIActivityIndicatorView {
    
    @objc class func mnz_init() -> UIActivityIndicatorView {
        var activityIndicatorView: UIActivityIndicatorView
        
        if #available(iOS 13.0, *) {
            activityIndicatorView = UIActivityIndicatorView.init(style: .medium)
            activityIndicatorView.color = (activityIndicatorView.traitCollection.userInterfaceStyle == UIUserInterfaceStyle.dark) ? UIColor.white : UIColor.mnz_primaryGray(for: activityIndicatorView.traitCollection)
        } else {
            activityIndicatorView = UIActivityIndicatorView.init(style: .gray)
            activityIndicatorView.color = UIColor.mnz_primaryGray(for: activityIndicatorView.traitCollection)
        }
        
        return activityIndicatorView
    }
}
