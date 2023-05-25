
protocol SingleTapHandlerProtocol {
    var singleTapGesture: UITapGestureRecognizer { get }
    var singleTapHandler: (() -> Void)? { get set }
    func addSingleTapGesture()
    func removeSingleTapGesture()
}

extension SingleTapHandlerProtocol where Self: UIView {
    var singleTapGesture: UITapGestureRecognizer { SingleTapGestureRecognizer(target: self, action: #selector(handleSingleTap(_:))) }
    
    func addSingleTapGesture() {
        if let gestures = gestureRecognizers?.filter({ $0 is SingleTapGestureRecognizer }),
            !gestures.isEmpty {
            return
        }
        
        addGestureRecognizer(singleTapGesture)
    }
    
    func removeSingleTapGesture() {
        gestureRecognizers?.filter({ $0 is SingleTapGestureRecognizer }).forEach({ removeGestureRecognizer($0) })
    }
}

extension UIView {
    @objc fileprivate func handleSingleTap(_ gesture: UITapGestureRecognizer) {
        guard let singleTapHandlerSelf = self as? SingleTapHandlerProtocol,
            let handler = singleTapHandlerSelf.singleTapHandler else {
            return
        }
        
        handler()
    }
}

private class SingleTapGestureRecognizer: UITapGestureRecognizer { }
