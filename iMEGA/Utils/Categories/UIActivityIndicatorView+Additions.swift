import MEGAAssets
import MEGADesignToken

extension UIActivityIndicatorView {
    
    @objc class func mnz_init() -> UIActivityIndicatorView {
        var activityIndicatorView: UIActivityIndicatorView
        
        activityIndicatorView = UIActivityIndicatorView.init(style: .medium)
        activityIndicatorView.color = (activityIndicatorView.traitCollection.userInterfaceStyle == UIUserInterfaceStyle.dark) ? MEGAAssets.UIColor.whiteFFFFFF : TokenColors.Text.secondary
        
        return activityIndicatorView
    }
}
