@testable import MEGA
import Testing
import UIKit

struct BottomOverlayLayoutTests {
    @Test(
        "The overlay sits above a horizontal tab bar, otherwise on the bottom safe area",
        arguments: [
            (isTabBarHidden: false, isTabBarHorizontal: true, expected: CGFloat(-83)),
            (isTabBarHidden: false, isTabBarHorizontal: false, expected: CGFloat(-34)),
            (isTabBarHidden: true, isTabBarHorizontal: true, expected: CGFloat(-34)),
            (isTabBarHidden: true, isTabBarHorizontal: false, expected: CGFloat(-34))
        ]
    )
    func bottomConstant(isTabBarHidden: Bool, isTabBarHorizontal: Bool, expected: CGFloat) {
        let constant = BottomOverlayLayout.bottomConstant(
            isTabBarHidden: isTabBarHidden,
            isTabBarHorizontal: isTabBarHorizontal,
            tabBarHeight: 83,
            safeAreaBottom: 34
        )

        #expect(constant == expected)
    }

    @Test(
        "The overlay keeps the side safe area only beside a visible vertical tab bar",
        arguments: [
            (isTabBarHidden: false, isTabBarHorizontal: false, isRightToLeft: false, leading: CGFloat(90), trailing: CGFloat(10)),
            (isTabBarHidden: false, isTabBarHorizontal: false, isRightToLeft: true, leading: CGFloat(10), trailing: CGFloat(90)),
            (isTabBarHidden: false, isTabBarHorizontal: true, isRightToLeft: false, leading: CGFloat(0), trailing: CGFloat(0)),
            (isTabBarHidden: true, isTabBarHorizontal: false, isRightToLeft: false, leading: CGFloat(0), trailing: CGFloat(0))
        ]
    )
    func sideInsets(
        isTabBarHidden: Bool,
        isTabBarHorizontal: Bool,
        isRightToLeft: Bool,
        leading: CGFloat,
        trailing: CGFloat
    ) {
        let insets = BottomOverlayLayout.sideInsets(
            isTabBarHidden: isTabBarHidden,
            isTabBarHorizontal: isTabBarHorizontal,
            isRightToLeft: isRightToLeft,
            safeArea: UIEdgeInsets(top: 0, left: 90, bottom: 34, right: 10)
        )

        #expect(insets.leading == leading)
        #expect(insets.trailing == trailing)
    }

    @Test(
        "Select mode pads by a horizontal tab bar and keeps the overlay inset beside a vertical one",
        arguments: [
            (isSelecting: true, isTabBarHorizontal: true, expected: CGFloat?(83)),
            (isSelecting: false, isTabBarHorizontal: true, expected: CGFloat?(0)),
            (isSelecting: true, isTabBarHorizontal: false, expected: CGFloat?.none),
            (isSelecting: false, isTabBarHorizontal: false, expected: CGFloat?.none)
        ]
    )
    func selectionModeBottomInset(isSelecting: Bool, isTabBarHorizontal: Bool, expected: CGFloat?) {
        let inset = BottomOverlayLayout.selectionModeBottomInset(
            isSelecting: isSelecting,
            isTabBarHorizontal: isTabBarHorizontal,
            tabBarHeight: 83
        )

        #expect(inset == expected)
    }
}
