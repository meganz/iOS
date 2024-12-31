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
    static func concatenate(plurals: [Plural], locale: Locale = .autoupdatingCurrent) -> String {
        let formattedPlurals = plurals
            .filter { $0.count > 0 }
            .map(\.localizedString)
            
        return formattedPlurals.formatted(.list(type: .and).locale(locale))
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

    /// For a string to be display in left-to-right direction
    /// For strings and tags that are bi-directional, iOS will use Unicode BIDI algorithm (https://www.unicode.org/reports/tr9/)
    /// to render the output string onto the UI. This algorithm will mess up strings that are supposed to be strictly Left-to-right
    /// such as node names and tags. This function will add a LTR mark to force the string to be displayed in LTR direction.
    /// - Returns: The forced-LTR version of the string
    func forceLeftToRight() -> String {
        "\u{200e}\(self)"
    }
}
