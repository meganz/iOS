import Foundation

@resultBuilder
enum SettingBuilder {
    static func buildBlock(_ components: SettingSectionViewModel...) -> [SettingSectionViewModel] {
        components
    }
}

@resultBuilder
enum SettingSectionBuilder {
    static func buildBlock(_ components: SettingCellViewModel...) -> [SettingCellViewModel] {
        components
    }
}
