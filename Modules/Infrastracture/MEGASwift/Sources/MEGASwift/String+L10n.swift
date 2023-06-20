import Foundation

public extension String {
    /// A structure that represents a count of items that need to be localised into a string.
    ///
    /// Use this structure when you need to pluralize and localise item counts into a string.
    struct Plural {
        /// The count of items to be localized.
        public let count: Int
        /// The localized string.
        ///
        /// This property is computed when the `Plural` instance is created and then stored for future access.
        public let localizedString: String
        
        public init(count: Int, localize: (Int) -> String) {
            self.count = count
            self.localizedString = localize(count)
        }
        
    }

    /// Concatenates the localized strings of an array of `Plural` instances into a single string.
    ///
    /// This method takes an array of `Plural` instances, filters out any instances where the count is 0,
    /// then localizes each count into a string and concatenates the localized strings into a single string.
    /// The localized strings are concatenated in a list format, with the type `.and`.
    ///
    /// - Parameter plurals: An array of `Plural` instances.
    /// - Returns: A string containing the localized strings of the `Plural` instances, concatenated in a list format.
    ///
    /// If the current iOS version is 15.0 or later, the `formatted(_:)` method is used for concatenation;
    /// otherwise, `ListFormatter.localizedString(byJoining:)` is used.
    static func concatenate(plurals: [Plural], locale: Locale = .autoupdatingCurrent) -> String {
        let formattedPlurals = plurals
            .filter { $0.count > 0 }
            .map(\.localizedString)
            
        if #available(iOS 15.0, *) {
            return formattedPlurals.formatted(.list(type: .and).locale(locale))
        } else {
            let formatter = ListFormatter()
            formatter.locale = locale
            return formatter.string(from: formattedPlurals) ?? ListFormatter.localizedString(byJoining: formattedPlurals)
        }
    }
    
    /// Injects an array of `Plural` instances into a localized string generator.
    ///
    /// This method first concatenates the localized strings of an array of `Plural` instances into a single string
    /// using the `concatenate(plurals:)` method. It then passes this concatenated string to the provided
    /// `stringGenerator` function, which should return a localized string incorporating the input.
    ///
    /// - Parameters:
    ///     - plurals: An array of `Plural` instances, each of which contains a count and a localization function.
    ///     - stringGenerator: A function that takes an input and generates a localized string incorporating this input.
    /// - Returns: A `String` which is the result of passing the concatenated localized strings to the `stringGenerator` function.
    ///
    /// For example, if `concatenate(plurals:)` returns "2 apples and 3 oranges", and `stringGenerator` is a function
    /// that returns "You have \(input)", then `inject(plurals:intoLocalized:)` will return "You have 2 apples and 3 oranges".
    static func inject(plurals: [Plural], intoLocalized stringGenerator: (Any) -> String) -> String {
        stringGenerator(concatenate(plurals: plurals))
    }
}
