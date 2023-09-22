import Foundation

extension String {
  func toCGFloat() -> CGFloat? {
    guard let doubleValue = Double(self) else {
        return nil
    }

    return CGFloat(doubleValue)
  }
}

extension String {
    func toPascalCase() -> String {
        self
            .split(separator: " ")
            .map { $0.capitalized }
            .joined()
    }
}

extension String {
    var isNumeric: Bool {
        CharacterSet.decimalDigits.isSuperset(of: .init(charactersIn: self))
    }
}
