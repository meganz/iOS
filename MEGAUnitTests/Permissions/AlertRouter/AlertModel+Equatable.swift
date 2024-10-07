@testable import MEGA

extension AlertModel: @retroactive Equatable {
    public static func == (lhs: AlertModel, rhs: AlertModel) -> Bool {
        lhs.title == rhs.title &&
        lhs.message == rhs.message &&
        lhs.actions == rhs.actions
    }
}

extension AlertModel.AlertAction: @retroactive Equatable {
    public static func == (lhs: AlertModel.AlertAction, rhs: AlertModel.AlertAction) -> Bool {
        lhs.title == rhs.title &&
        lhs.style == rhs.style
    }
}
