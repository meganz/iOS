import Foundation

extension String {
    func toCGFloat() -> CGFloat? {
        guard let doubleValue = Double(self) else {
            return nil
        }

        return CGFloat(doubleValue)
    }

    func toPascalCase() -> String {
        self
            .split(separator: " ")
            .map { $0.capitalized }
            .joined()
    }

    func toCamelCase() -> String {
        let pascalCased = self.toPascalCase()

        return pascalCased.prefix(1).lowercased() + pascalCased.dropFirst()
    }

    func deletingPrefix(_ prefix: String) -> String {
        guard self.hasPrefix(prefix) else { return self }
        return String(self.dropFirst(prefix.count))
    }
}
