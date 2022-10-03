import Foundation

@resultBuilder
enum SlideShowOptionBuilder {
    static func buildBlock(_ components: SlideShowOptionCellViewModel...) -> [SlideShowOptionCellViewModel] {
        components
    }
}

@resultBuilder
enum SlideShowOptionChildrenBuilder {
    static func buildBlock(_ components: SlideShowOptionDetailCellViewModel...) -> [SlideShowOptionDetailCellViewModel] {
        components
    }
}
