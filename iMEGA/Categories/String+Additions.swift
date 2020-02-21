
extension String {
    var mnz_isDecimalNumber: Bool {
        return CharacterSet.decimalDigits.isSuperset(of: CharacterSet(charactersIn: self))
    }
}
