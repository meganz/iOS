struct MegaDataFormatter {
    // MARK: - Properties

    public static let shared = MegaDataFormatter()

    private let formatter = DateFormatter()

    // MARK: - Initializer

    private init() {}
    
    // MARK: - Methods
    
    public func string(fromDate date: Date, dateFormat: String) -> String {
        formatter.dateFormat = dateFormat
        return formatter.string(from: date)
    }
    
    public func attributedString(from date: Date,
                                 dateFormat: String,
                                 with attributes: [NSAttributedString.Key: Any]) -> NSAttributedString {
        let dateString = string(fromDate: date, dateFormat: dateFormat)
        return NSAttributedString(string: dateString, attributes: attributes)
    }
}
