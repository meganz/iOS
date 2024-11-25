import MEGADesignToken
import MEGASwiftUI
import SwiftUI

struct ExistingTagsLoadingView: View {
    @State private var isShimmeringInitialState = true
    private let padding: CGFloat = TokenSpacing._3
    private let placeholderViewHeight: CGFloat = 30
    private let rows: Int
    private let columns: Int
    private let widthFactors: [[CGFloat]]

    init(rows: Int = 3, columns: Int = 3) {
        self.rows = rows
        self.columns = columns

        // Closure to generate an array of normalized random width factors for a given number of columns
        let columnWidthFactors = { (columns: Int) in
            // Generate an array of random CGFloat values between 0.1 and 1.0 for each column
            let randomValues = (0..<columns).map { _ in CGFloat.random(in: 0.1...1.0) }
            // Calculate the sum of all random values
            let sum = randomValues.reduce(0, +)
            // Normalize the random values so they add up to 1 and return the result
            return randomValues.map { $0 / sum }
        }

        // Generate a 2D array of width factors for the grid
        // Each row gets its own array of normalized random column width factors
        self.widthFactors = (0..<rows).map { _ in columnWidthFactors(columns) }
    }

    var body: some View {
        GeometryReader { proxy in
            contentView(for: proxy.size.width)
                .mask(gradientView)
                .animation(
                    .linear(duration: 1.5).delay(0.25).repeatForever(autoreverses: false),
                    value: isShimmeringInitialState
                )
                .onAppear {
                    isShimmeringInitialState = false
                }
        }
    }

    private var gradientView: some View {
        LinearGradient(
            gradient: .init(
                colors: [placeholderColor, placeholderColor.opacity(0.4), placeholderColor]
            ),
            startPoint: (isShimmeringInitialState ? .init(x: -0.3, y: -0.3) : .init(x: 1, y: 1)),
            endPoint: (isShimmeringInitialState ? .init(x: 0, y: 0) : .init(x: 1.3, y: 1.3))
        )
    }

    private var placeholderColor: Color {
        TokenColors.Background.surface2.swiftUI
    }

    private func contentView(for availableWidth: CGFloat) -> some View {
        VStack(spacing: padding) {
            ForEach(0..<rows, id: \.self) { row in
                columnView(for: availableWidth, row: row)
            }
        }
    }

    private func columnView(for availableWidth: CGFloat, row: Int) -> some View {
        HStack(spacing: padding) {
            let placeholderTotalWidth = availableWidth - (padding * CGFloat((columns - 1)))
            ForEach(0..<columns, id: \.self) { column in
                placeholderView(
                    width: placeholderTotalWidth * widthFactors[row][column],
                    height: placeholderViewHeight
                )
            }
        }
    }

    private func placeholderView(width: CGFloat, height: CGFloat) -> some View {
        placeholderColor
            .cornerRadius(TokenRadius.medium)
            .frame(width: width, height: height)
    }
}
