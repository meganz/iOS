import MEGAL10n
import MEGAUIComponent

extension SortOptionsViewModel {
    static var folderLink: Self {
        Self.init(
            title: Strings.Localizable.sortTitle,
            sortOptions: [] // IOS-11091
        )
    }
}
