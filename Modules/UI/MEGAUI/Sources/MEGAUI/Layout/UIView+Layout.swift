import UIKit

public extension UIView {
    func wrap(_ view: UIView,
              edgeInsets insets: UIEdgeInsets = .zero,
              excludeConstraints: Set<NSLayoutConstraint.Attribute> = []) {
         view.translatesAutoresizingMaskIntoConstraints = false
         addSubview(view)
         
        if !excludeConstraints.contains(.top) {
            let topInset = insets.top * -1
            topAnchor.constraint(equalTo: view.topAnchor, constant: topInset).isActive = true
        }
        
        if !excludeConstraints.contains(.bottom) {
            bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: insets.bottom).isActive = true
        }
        
        if !excludeConstraints.contains(.leading) {
            let leftInset = insets.left * -1
            leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: leftInset).isActive = true
        }
        
        if !excludeConstraints.contains(.trailing) {
            trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: insets.right).isActive = true
        }
    }
    
    static func makeFlexiView(for axis: NSLayoutConstraint.Axis) -> UIView {
        let view = UIView()
        view.setContentCompressionResistancePriority(.defaultLow, for: axis)
        return view
    }
}
