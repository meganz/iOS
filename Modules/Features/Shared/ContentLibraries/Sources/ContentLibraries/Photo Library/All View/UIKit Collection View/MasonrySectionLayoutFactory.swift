import UIKit

@MainActor
enum MasonrySectionLayoutFactory {

    static func makeMasonrySection(
        layoutEnvironment: some NSCollectionLayoutEnvironment,
        spacing: CGFloat = 4
    ) -> NSCollectionLayoutSection {
        let contentWidth = layoutEnvironment.container.effectiveContentSize.width
        let cellSize = (contentWidth - (spacing * 2)) / 3.0

        let superGroup = createSuperMasonryGroup(cellSize: cellSize, spacing: spacing)

        let section = NSCollectionLayoutSection(group: superGroup)
        section.interGroupSpacing = spacing

        return section
    }

    static func createSuperMasonryGroup(cellSize: CGFloat, spacing: CGFloat) -> NSCollectionLayoutGroup {
        let evenGroup = createMasonryGroup(cellSize: cellSize, spacing: spacing, isEven: true)
        let oddGroup = createMasonryGroup(cellSize: cellSize, spacing: spacing, isEven: false)

        let superGroupHeight = (cellSize * 3 + spacing * 2) * 2 + spacing
        let superGroupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .absolute(superGroupHeight)
        )

        let superGroup = NSCollectionLayoutGroup.vertical(
            layoutSize: superGroupSize,
            subitems: [evenGroup, oddGroup]
        )
        superGroup.interItemSpacing = .fixed(spacing)

        return superGroup
    }

    static func createMasonryGroup(cellSize: CGFloat, spacing: CGFloat, isEven: Bool) -> NSCollectionLayoutGroup {
        if isEven {
            buildEvenMasonryGroup(cellSize: cellSize, spacing: spacing)
        } else {
            buildOddMasonryGroup(cellSize: cellSize, spacing: spacing)
        }
    }

    // MARK: - Private

    private static func buildEvenMasonryGroup(cellSize: CGFloat, spacing: CGFloat) -> NSCollectionLayoutGroup {
        let largeItemSize = NSCollectionLayoutSize(
            widthDimension: .absolute(cellSize * 2 + spacing),
            heightDimension: .absolute(cellSize * 2 + spacing)
        )
        let largeItem = NSCollectionLayoutItem(layoutSize: largeItemSize)

        let regularItemSize = NSCollectionLayoutSize(
            widthDimension: .absolute(cellSize),
            heightDimension: .absolute(cellSize)
        )

        let topRightStackSize = NSCollectionLayoutSize(
            widthDimension: .absolute(cellSize),
            heightDimension: .absolute(cellSize * 2 + spacing)
        )
        let topRightStack = NSCollectionLayoutGroup.vertical(
            layoutSize: topRightStackSize,
            repeatingSubitem: NSCollectionLayoutItem(layoutSize: regularItemSize),
            count: 2
        )
        topRightStack.interItemSpacing = .fixed(spacing)

        let topRowSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .absolute(cellSize * 2 + spacing)
        )
        let topRow = NSCollectionLayoutGroup.horizontal(
            layoutSize: topRowSize,
            subitems: [largeItem, topRightStack]
        )
        topRow.interItemSpacing = .fixed(spacing)

        let bottomRowSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .absolute(cellSize)
        )
        let bottomRow = NSCollectionLayoutGroup.horizontal(
            layoutSize: bottomRowSize,
            repeatingSubitem: NSCollectionLayoutItem(layoutSize: regularItemSize),
            count: 3
        )
        bottomRow.interItemSpacing = .fixed(spacing)

        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .absolute(cellSize * 3 + spacing * 2)
        )
        let group = NSCollectionLayoutGroup.vertical(
            layoutSize: groupSize,
            subitems: [topRow, bottomRow]
        )
        group.interItemSpacing = .fixed(spacing)

        return group
    }

    private static func buildOddMasonryGroup(cellSize: CGFloat, spacing: CGFloat) -> NSCollectionLayoutGroup {
        let largeItemSize = NSCollectionLayoutSize(
            widthDimension: .absolute(cellSize * 2 + spacing),
            heightDimension: .absolute(cellSize * 2 + spacing)
        )
        let largeItem = NSCollectionLayoutItem(layoutSize: largeItemSize)

        let regularItemSize = NSCollectionLayoutSize(
            widthDimension: .absolute(cellSize),
            heightDimension: .absolute(cellSize)
        )

        let topLeftStackSize = NSCollectionLayoutSize(
            widthDimension: .absolute(cellSize),
            heightDimension: .absolute(cellSize * 2 + spacing)
        )
        let topLeftStack = NSCollectionLayoutGroup.vertical(
            layoutSize: topLeftStackSize,
            repeatingSubitem: NSCollectionLayoutItem(layoutSize: regularItemSize),
            count: 2
        )
        topLeftStack.interItemSpacing = .fixed(spacing)

        let topRowSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .absolute(cellSize * 2 + spacing)
        )
        let topRow = NSCollectionLayoutGroup.horizontal(
            layoutSize: topRowSize,
            subitems: [topLeftStack, largeItem]
        )
        topRow.interItemSpacing = .fixed(spacing)

        let bottomRowSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .absolute(cellSize)
        )
        let bottomRow = NSCollectionLayoutGroup.horizontal(
            layoutSize: bottomRowSize,
            repeatingSubitem: NSCollectionLayoutItem(layoutSize: regularItemSize),
            count: 3
        )
        bottomRow.interItemSpacing = .fixed(spacing)

        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .absolute(cellSize * 3 + spacing * 2)
        )
        let group = NSCollectionLayoutGroup.vertical(
            layoutSize: groupSize,
            subitems: [topRow, bottomRow]
        )
        group.interItemSpacing = .fixed(spacing)

        return group
    }
}
