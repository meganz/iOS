import Combine
import MEGAL10n

extension MediaTabSharedResourceProvider {
    /// Creates a publisher that emits the appropriate navigation title based on edit mode
    /// and the current selection count.
    ///
    /// - When edit mode is **active**:
    ///   - Emits a generic “Select” title when the selection count is `0`.
    ///   - Emits a formatted “N items selected” title when one or more items are selected.
    /// - When edit mode is **inactive**:
    ///   - Emits a fixed title provided by `inactiveEditModeTitle`.
    ///
    /// The returned publisher automatically switches between the edit-mode–driven title
    /// and the inactive title as `editModePublisher` changes, suppressing duplicate
    /// consecutive values.
    ///
    /// - Parameters:
    ///   - selectionCountPublisher: A publisher that emits the current number of selected items.
    ///   - inactiveEditModeTitle: The title to emit when edit mode is inactive.
    ///     Defaults to the media section title.
    ///
    /// - Returns: A type-erased publisher that emits the resolved title string for display.
    func selectionTitlePublisher(
        selectionCountPublisher: AnyPublisher<Int, Never>,
        inactiveEditModeTitle: String = Strings.Localizable.Photos.SearchResults.Media.Section.title
    ) -> AnyPublisher<String, Never> {
        editModePublisher
            .map {
                if $0.isEditing {
                    selectionCountPublisher
                        .map { count in
                            if count == 0 {
                                Strings.Localizable.selectTitle
                            } else {
                                Strings.Localizable.General.Format.itemsSelected(count)
                            }
                        }
                        .eraseToAnyPublisher()
                } else {
                    Just(inactiveEditModeTitle)
                        .eraseToAnyPublisher()
                }
            }
            .switchToLatest()
            .removeDuplicates()
            .eraseToAnyPublisher()
    }
}
