@testable import MEGA

extension CustomModalModel: @retroactive Equatable {
    public static func == (lhs: CustomModalModel, rhs: CustomModalModel) -> Bool {
        lhs.image.pngData() == rhs.image.pngData() &&
        lhs.viewTitle == rhs.viewTitle &&
        lhs.details == rhs.details &&
        lhs.firstButtonTitle == rhs.firstButtonTitle &&
        lhs.dismissButtonTitle == rhs.dismissButtonTitle
    }
}
