import UIKit

public extension [UIView] {

    @MainActor
    func embedInStackView(
        axis: NSLayoutConstraint.Axis = .horizontal,
        distribution: UIStackView.Distribution = .fill,
        alignment: UIStackView.Alignment = .fill,
        spacing: CGFloat = 8,
        isBaselineRelativeArrangement: Bool = false,
        isLayoutMarginsRelativeArrangement: Bool = false
    ) -> UIStackView {
        let stackView = UIStackView(arrangedSubviews: self)
        stackView.axis = axis
        stackView.alignment = alignment
        stackView.distribution = distribution
        stackView.spacing = spacing
        stackView.isBaselineRelativeArrangement = isBaselineRelativeArrangement
        stackView.isLayoutMarginsRelativeArrangement = isLayoutMarginsRelativeArrangement
        return stackView
    }

    @MainActor
    private func embedInHorizontalStackView(
        distribution: UIStackView.Distribution,
        alignment: UIStackView.Alignment = .fill,
        spacing: CGFloat = 8,
        isBaselineRelativeArrangement: Bool = false,
        isLayoutMarginsRelativeArrangement: Bool = false
    ) -> UIStackView {
        return embedInStackView(
            axis: .horizontal,
            distribution: distribution,
            alignment: alignment,
            isBaselineRelativeArrangement: isBaselineRelativeArrangement,
            isLayoutMarginsRelativeArrangement: isLayoutMarginsRelativeArrangement
        )
    }

    @MainActor
    private func embedInVerticalStackView(
        distribution: UIStackView.Distribution,
        alignment: UIStackView.Alignment = .fill,
        spacing: CGFloat = 8,
        isBaselineRelativeArrangement: Bool = false,
        isLayoutMarginsRelativeArrangement: Bool = false
    ) -> UIStackView {
        return embedInStackView(
            axis: .vertical,
            distribution: distribution,
            alignment: alignment,
            isBaselineRelativeArrangement: isBaselineRelativeArrangement,
            isLayoutMarginsRelativeArrangement: isLayoutMarginsRelativeArrangement
        )
    }
}
