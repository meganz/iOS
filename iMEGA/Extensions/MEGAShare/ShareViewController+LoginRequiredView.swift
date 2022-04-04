import CoreGraphics
extension ShareViewController {
    @objc func addLoginRequiredView() {
        guard let loginRequiredNC = loginRequiredNC else {
            return
        }
        
        if loginRequiredNC.parent == self {
            return
        }
        
        addChild(loginRequiredNC)
        loginRequiredNC.view.frame = CGRect(x: 0.0, y: 0.0, width: view.frame.size.width, height: view.frame.size.height)
        view.addSubview(loginRequiredNC.view)
    }
    
    @objc func removeLoginRequiredView() {
        guard let loginRequiredNC = loginRequiredNC else {
            return
        }
        
        loginRequiredNC.removeFromParent()
        loginRequiredNC.view.removeFromSuperview()
    }
}
