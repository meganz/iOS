
extension UIViewController {
    class func instantiate(withStoryboardName name: String) -> Self {
        return instantiate(withStoryboard: UIStoryboard(name: name, bundle: nil), forViewController: self)
    }
    
    class func instantiate(withStoryboard storyboard: UIStoryboard) -> Self {
        return instantiate(withStoryboard: storyboard, forViewController: self)
    }
    
    class func instantiate<T>(withStoryboard storyboard: UIStoryboard, forViewController controller: T.Type) -> T {
        return storyboard.instantiateViewController(withIdentifier: String(describing: self)) as! T
    }
}
