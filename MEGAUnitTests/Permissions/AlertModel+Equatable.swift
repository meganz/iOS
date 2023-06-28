@testable import MEGA

extension AlertModel: Equatable {
    public static func == (lhs: AlertModel, rhs: AlertModel) -> Bool {
        lhs.title == rhs.title &&
        lhs.message == rhs.message &&
        lhs.actions == rhs.actions
    }
}

extension AlertModel.AlertAction: Equatable {
    public static func == (lhs: AlertModel.AlertAction, rhs: AlertModel.AlertAction) -> Bool {
        lhs.title == rhs.title &&
        lhs.style == rhs.style
    }
}
