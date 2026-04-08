import Foundation

public enum ShortcutType: CaseIterable, Identifiable {
    case favourites
    case audios
    case offline

    public var id: Self { self }
}
