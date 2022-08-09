
class SingleTapView: UIView, SingleTapHandlerProtocol {
    // MARK:- SingleTapHandlerProtocol
    
    var singleTapHandler: (() -> Void)? {
        didSet {
            if singleTapHandler != nil {
                addSingleTapGesture()
            } else {
                removeSingleTapGesture()
            }
        }
    }
}
