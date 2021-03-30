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
                let y = self.frame.width - thickness
                border.frame = CGRect(x: 0, y: y, width: self.frame.width, height: thickness)
            case .left:
                border.frame = CGRect(x: 0, y: 0, width: thickness, height: self.frame.height)
            case .right:
                let x = self.frame.width - thickness
                border.frame = CGRect(x: x, y: 0, width: thickness, height: self.frame.height)
            default:
                break
            }

            self.addSublayer(border)
        }
    }
}
