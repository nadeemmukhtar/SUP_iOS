//
//  PhotoCollectionView.swift
//  sup
//
//  Created by Robert Malko on 11/17/19.
//  Copyright © 2019 Episode 8, Inc.. All rights reserved.
//

import Foundation
import UIKit

#if canImport(ASCollectionView)
import ASCollectionView

struct CollectionLayouts {
    static func grid(
        columns: Int = 2,
        contentInsets: NSDirectionalEdgeInsets = .init(
            top: 0, leading: 0, bottom: 0, trailing: 0
        ),
        itemSpacing: CGFloat = 5,
        lineSpacing: CGFloat = 5,
        itemSize: NSCollectionLayoutDimension = .estimated(150)
    ) -> ASCollectionLayout<Int> {
        ASCollectionLayout(scrollDirection: .vertical, interSectionSpacing: CGFloat(0)) {
            ASCollectionLayoutSection { (layoutEnvironment) in
                let count = columns
                let itemLayoutSize = NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1.0),
                    heightDimension: itemSize
                )
                let groupSize = NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1.0),
                    heightDimension: itemSize
                )
                let supplementarySize = NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1.0),
                    heightDimension: .estimated(50)
                )
                let item = NSCollectionLayoutItem(layoutSize: itemLayoutSize)

                let group = NSCollectionLayoutGroup.horizontal(
                    layoutSize: groupSize,
                    subitem: item,
                    count: count
                )
                group.interItemSpacing = .fixed(itemSpacing)

                let section = NSCollectionLayoutSection(group: group)
                section.interGroupSpacing = lineSpacing
                section.contentInsets = contentInsets

                let headerSupplementary = NSCollectionLayoutBoundarySupplementaryItem(
                    layoutSize: supplementarySize,
                    elementKind: UICollectionView.elementKindSectionHeader,
                    alignment: .top
                )
                let footerSupplementary = NSCollectionLayoutBoundarySupplementaryItem(
                    layoutSize: supplementarySize,
                    elementKind: UICollectionView.elementKindSectionFooter,
                    alignment: .bottom
                )
                section.boundarySupplementaryItems = [
                    headerSupplementary,
                    footerSupplementary
                ]
                return section
            }
        }
    }

    static func mosaicGrid() -> ASCollectionLayout<Int> {
        ASCollectionLayout(scrollDirection: .vertical, interSectionSpacing: CGFloat(0)) {
            ASCollectionLayoutSection { environment in
                let isWide = environment.container.effectiveContentSize.width > 500
                let gridBlockSize = environment.container.effectiveContentSize.width / (isWide ? 5 : 3)
                let gridItemInsets = NSDirectionalEdgeInsets(top: 1, leading: 1, bottom: 1, trailing: 1)
                let itemSize = NSCollectionLayoutSize(
                    widthDimension: .absolute(gridBlockSize),
                    heightDimension: .absolute(gridBlockSize)
                )
                let item = NSCollectionLayoutItem(layoutSize: itemSize)
                item.contentInsets = gridItemInsets
                let verticalGroupSize = NSCollectionLayoutSize(
                    widthDimension: .absolute(gridBlockSize),
                    heightDimension: .absolute(gridBlockSize * 2)
                )
                let verticalGroup = NSCollectionLayoutGroup.vertical(
                    layoutSize: verticalGroupSize,
                    subitem: item,
                    count: 2
                )

                let featureItemSize = NSCollectionLayoutSize(
                    widthDimension: .absolute(gridBlockSize * 2),
                    heightDimension: .absolute(gridBlockSize * 2)
                )
                let featureItem = NSCollectionLayoutItem(layoutSize: featureItemSize)
                featureItem.contentInsets = gridItemInsets

                let fullWidthItemSize = NSCollectionLayoutSize(
                    widthDimension: .absolute(environment.container.effectiveContentSize.width),
                    heightDimension: .absolute(gridBlockSize * 2)
                )
                let fullWidthItem = NSCollectionLayoutItem(layoutSize: fullWidthItemSize)
                fullWidthItem.contentInsets = gridItemInsets

                let verticalAndFeatureGroupSize = NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1.0),
                    heightDimension: .absolute(gridBlockSize * 2)
                )
                let verticalAndFeatureGroupA = NSCollectionLayoutGroup.horizontal(
                    layoutSize: verticalAndFeatureGroupSize,
                    subitems: isWide ?
                        [verticalGroup, verticalGroup, featureItem, verticalGroup] :
                        [verticalGroup, featureItem]
                )
                let verticalAndFeatureGroupB = NSCollectionLayoutGroup.horizontal(
                    layoutSize: verticalAndFeatureGroupSize,
                    subitems: isWide ?
                        [verticalGroup, featureItem, verticalGroup, verticalGroup] :
                        [featureItem, verticalGroup]
                )

                let rowGroupSize = NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1.0),
                    heightDimension: .absolute(gridBlockSize)
                )
                let rowGroup = NSCollectionLayoutGroup.horizontal(
                    layoutSize: rowGroupSize,
                    subitem: item,
                    count: isWide ? 5 : 3
                )

                let outerGroupSize = NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1.0),
                    heightDimension: .absolute(gridBlockSize * 8)
                )
                let outerGroup = NSCollectionLayoutGroup.vertical(
                    layoutSize: outerGroupSize,
                    subitems: [
                        verticalAndFeatureGroupA,
                        rowGroup,
                        fullWidthItem,
                        verticalAndFeatureGroupB,
                        rowGroup
                    ]
                )

                let section = NSCollectionLayoutSection(group: outerGroup)
                return section
            }
        }
    }
}

struct CollectionLayoutSections {
    static func horizontal(
        itemSize size: CGSize,
        insets: NSDirectionalEdgeInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0),
        spacing: CGFloat = 10.0,
        behavior: UICollectionLayoutSectionOrthogonalScrollingBehavior = .continuous
    ) -> ASCollectionLayoutSection {
        return ASCollectionLayoutSection { environment in
            let itemSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .fractionalHeight(1.0)
            )
            let item = NSCollectionLayoutItem(layoutSize: itemSize)

            let groupSize = NSCollectionLayoutSize(
                widthDimension: .absolute(size.width),
                heightDimension: .absolute(size.height)
            )
            let group = NSCollectionLayoutGroup.horizontal(
                layoutSize: groupSize,
                subitems: [item]
            )
            group.edgeSpacing = NSCollectionLayoutEdgeSpacing(
                leading: .fixed(0),
                top: nil,
                trailing: .fixed(0),
                bottom: nil
            )

            let section = NSCollectionLayoutSection(group: group)
            section.interGroupSpacing = spacing
            section.contentInsets = insets
            section.orthogonalScrollingBehavior = behavior
            return section
        }
    }

    static func mosaicGrid() -> ASCollectionLayoutSection {
        return ASCollectionLayoutSection { environment in
            let isWide = environment.container.effectiveContentSize.width > 500
            let gridBlockSize = environment.container.effectiveContentSize.width / (isWide ? 5 : 3)
            let gridItemInsets = NSDirectionalEdgeInsets(top: 1, leading: 1, bottom: 1, trailing: 1)
            let itemSize = NSCollectionLayoutSize(
                widthDimension: .absolute(gridBlockSize),
                heightDimension: .absolute(gridBlockSize)
            )
            let item = NSCollectionLayoutItem(layoutSize: itemSize)
            item.contentInsets = gridItemInsets
            let verticalGroupSize = NSCollectionLayoutSize(
                widthDimension: .absolute(gridBlockSize),
                heightDimension: .absolute(gridBlockSize * 2)
            )
            let verticalGroup = NSCollectionLayoutGroup.vertical(
                layoutSize: verticalGroupSize,
                subitem: item,
                count: 2
            )

            let featureItemSize = NSCollectionLayoutSize(
                widthDimension: .absolute(gridBlockSize * 2),
                heightDimension: .absolute(gridBlockSize * 2)
            )
            let featureItem = NSCollectionLayoutItem(layoutSize: featureItemSize)
            featureItem.contentInsets = gridItemInsets

            let fullWidthItemSize = NSCollectionLayoutSize(
                widthDimension: .absolute(environment.container.effectiveContentSize.width),
                heightDimension: .absolute(gridBlockSize * 2)
            )
            let fullWidthItem = NSCollectionLayoutItem(layoutSize: fullWidthItemSize)
            fullWidthItem.contentInsets = gridItemInsets

            let verticalAndFeatureGroupSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .absolute(gridBlockSize * 2)
            )
            let verticalAndFeatureGroupA = NSCollectionLayoutGroup.horizontal(
                layoutSize: verticalAndFeatureGroupSize,
                subitems: isWide ?
                    [verticalGroup, verticalGroup, featureItem, verticalGroup] :
                    [verticalGroup, featureItem]
            )
            let verticalAndFeatureGroupB = NSCollectionLayoutGroup.horizontal(
                layoutSize: verticalAndFeatureGroupSize,
                subitems: isWide ?
                    [verticalGroup, featureItem, verticalGroup, verticalGroup] :
                    [featureItem, verticalGroup]
            )

            let rowGroupSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .absolute(gridBlockSize)
            )
            let rowGroup = NSCollectionLayoutGroup.horizontal(
                layoutSize: rowGroupSize,
                subitem: item,
                count: isWide ? 5 : 3
            )

            let outerGroupSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .absolute(gridBlockSize * 8)
            )
            let outerGroup = NSCollectionLayoutGroup.vertical(
                layoutSize: outerGroupSize,
                subitems: [
                    verticalAndFeatureGroupA,
                    rowGroup,
                    fullWidthItem,
                    verticalAndFeatureGroupB,
                    rowGroup
                ]
            )

            let section = NSCollectionLayoutSection(group: outerGroup)
            return section
        }
    }
}
#endif
