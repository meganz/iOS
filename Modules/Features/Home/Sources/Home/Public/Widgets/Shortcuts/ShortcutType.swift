import Foundation

public enum ShortcutType: CaseIterable, Identifiable {
    case favourites
    case videos
    case offline

    public var id: Self { self }
}
