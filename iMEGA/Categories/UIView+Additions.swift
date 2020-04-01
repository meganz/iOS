
extension UIView {
    class var instanceFromNib: Self {
        return Bundle(for: Self.self)
            .loadNibNamed(String(describing: Self.self), owner: nil, options: nil)?.first as! Self
    }
}
