import UIKit

public extension UIView {
    func wrap(_ view: UIView, edgeInsets insets: UIEdgeInsets = .zero) {
        view.translatesAutoresizingMaskIntoConstraints = false
        addSubview(view)
        
        let topInset = insets.top * -1
        let leftInset = insets.left * -1
        [topAnchor.constraint(equalTo: view.topAnchor, constant: topInset),
         bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: insets.bottom),
         leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: leftInset),
         trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: insets.right)].activate()
    }
    
    static func makeFlexiView(for axis: NSLayoutConstraint.Axis) -> UIView {
        let view = UIView()
        view.setContentCompressionResistancePriority(.defaultLow, for: axis)
        return view
    }
}
