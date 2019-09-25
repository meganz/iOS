
extension UIViewController {
    class func mnz_instantiate(withStoryboardName name: String) -> Self {
        return mnz_instantiate(withStoryboard: UIStoryboard(name: name, bundle: nil), forViewController: self)
    }
    
    class func mnz_instantiate(withStoryboard storyboard: UIStoryboard) -> Self {
        return mnz_instantiate(withStoryboard: storyboard, forViewController: self)
    }
    
    class func mnz_instantiate<T>(withStoryboard storyboard: UIStoryboard, forViewController controller: T.Type) -> T {
        return storyboard.instantiateViewController(withIdentifier: String(describing: self)) as! T
    }
}
