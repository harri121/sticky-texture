//
//  StickyUICollectionViewLayout.swift
//  Pods
//
//  Created by Daniel Hariri on 21.09.20.
//

import UIKit

public class StickyUICollectionViewFlowLayout: UICollectionViewFlowLayout {

    public override var collectionViewContentSize: CGSize {
        guard let collectionView = collectionView else {
            return super.collectionViewContentSize
        }
        let collectionViewHeight = collectionView.bounds.height
        let safeInsetBottom = collectionView.safeAreaInsets.bottom
        let minHeight = collectionViewHeight - safeInsetBottom
        let size = super.collectionViewContentSize
        if size.height < collectionViewHeight {
            return CGSize(width: size.width, height: minHeight)
        }
        return size
    }
}
