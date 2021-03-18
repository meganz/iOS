import Foundation

extension CALayer {
    func addBorder(edge: UIRectEdge, color: UIColor, thickness: CGFloat) {
        
        DispatchQueue.main.async {
            let border = CALayer()
            border.backgroundColor = color.cgColor

            switch edge {
            case .top:
                border.frame = CGRect(x: 0, y: 0, width: self.frame.width, height: thickness)
            case .bottom:
                border.frame = CGRect(x: 0, y: self.frame.width - thickness, width: self.frame.width, height: thickness)
            case .left:
                border.frame = CGRect(x: 0, y: 0, width: thickness, height: self.frame.height)
            case .right:
                border.frame = CGRect(x: self.frame.width - thickness, y: 0, width: thickness, height: self.frame.height)
            default:
                break
            }

            self.addSublayer(border)
        }
    }
}
