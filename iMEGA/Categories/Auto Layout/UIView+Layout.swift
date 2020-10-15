import Foundation

extension UIView {
    func wrap(_ view: UIView, edgeInsets insets: UIEdgeInsets = .zero) {
        view.translatesAutoresizingMaskIntoConstraints = false
        addSubview(view)
        
        [topAnchor.constraint(equalTo: view.topAnchor, constant: -insets.top),
         bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: insets.bottom),
         leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: -insets.left),
         trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: insets.right)].activate()
    }
}
