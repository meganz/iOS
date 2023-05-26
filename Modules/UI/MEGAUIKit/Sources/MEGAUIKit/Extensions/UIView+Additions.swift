import UIKit

public extension UIView {
    @IBInspectable var mnz_cornerRadius: CGFloat {
        get {
            return layer.cornerRadius
        }
        
        set {
            layer.cornerRadius = newValue
        }
    }
    
    @IBInspectable var borderColor: UIColor? {
        get {
            if let color = layer.borderColor {
                return UIColor(cgColor: color)
            }
            return nil
        }
        
        set {
            if let color = newValue {
                layer.borderColor = color.cgColor
            } else {
                layer.borderColor = nil
            }
        }
    }
    
    @IBInspectable var borderWidth: CGFloat {
        get {
            return layer.borderWidth
        }
        
        set {
            layer.borderWidth = newValue
        }
    }
    
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
