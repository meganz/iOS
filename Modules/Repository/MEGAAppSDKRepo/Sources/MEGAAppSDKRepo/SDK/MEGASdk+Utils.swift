import MEGASdk

public extension MEGASdk {
    /// Generic function to get an array of items.
    /// - Parameters:
    ///   - numberOfItems: The total number of items.
    ///   - itemAtIndexClosure: A closure that returns an item at a specific index.
    /// - Returns: An array of items of type T.
    static func fetchItems<T: NSObject>(
        numberOfItems: Int,
        itemAtIndexClosure: @escaping (Int) -> T?
    ) -> [T] {
        (0..<numberOfItems).compactMap { index in
            itemAtIndexClosure(index)
        }
    }
}
