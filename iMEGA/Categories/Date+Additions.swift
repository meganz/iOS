
extension Date {
    func string(withDateFormat dateFormat: String) -> String {
        return MegaDataFormatter.shared.string(fromDate: self, dateFormat: dateFormat)
    }
}
