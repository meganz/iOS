
@objc enum AlbumsSelectionActionType: Int, CaseIterable {
    case send
    case upload
    
    func localizedTextWithCount(_ count: Int) -> String {
        switch self {
        case .send: return Strings.Localizable.sendD(count)
        case .upload: return Strings.Localizable.uploadD(count)
        }
    }
}
