import Foundation

public enum AchievementTypeEntity: Int, CaseIterable, Sendable {
    case welcome = 1
    case invite = 3
    case desktopInstall = 4
    case mobileInstall = 5
    case addPhone = 9
}
