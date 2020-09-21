//
//  StickyNavigationBarNode.swift
//  Pods
//
//  Created by Daniel Hariri on 21.09.20.
//

import AsyncDisplayKit

public class StickyNavigationBarNode: ASDisplayNode {
    
    public var height: CGFloat {
        return 64.0
    }
    
    public override init() {
        super.init()
        setup()
    }
    
    private func setup() {
        backgroundColor = .clear
        clipsToBounds = true
        style.width = ASDimension(unit: .fraction, value: 1.0)
        style.height = ASDimension(unit: .points, value: height)
    }
    
    public func setCollapseProgress(_ progress: CGFloat, animated: Bool) {}
}

