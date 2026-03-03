import Foundation

public enum ShortcutType: CaseIterable, Identifiable {
    case favourites
    case offline

    public var id: Self { self }
}
