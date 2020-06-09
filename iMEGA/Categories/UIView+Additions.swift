
extension UIView {
    class var instanceFromNib: Self {
        guard let view =  Bundle(for: Self.self)
            .loadNibNamed(classNameString, owner: nil, options: nil)?.first as? Self else {
                fatalError("could not load the instance from nib")
        }
        
        return view
    }
    
    class var nib: UINib {
        return UINib(nibName: classNameString, bundle: nil)
    }
    
    class var reuseIdentifier: String {
        return classNameString
    }
    
    class var classNameString: String {
        return String(describing: Self.self)
    }
}
