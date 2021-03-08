
extension UIViewController {
    
    /// A Boolean value indicating whether the view is currently loaded into memory and the view has been added to a window.
    @objc func isViewReady() -> Bool {
        isViewLoaded && (view.window != nil)
    }
    
}
