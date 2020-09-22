//
//  StickyHeaderNode.swift
//  Pods
//
//  Created by Daniel Hariri on 21.09.20.
//

import AsyncDisplayKit

open class StickyHeaderNode: ASDisplayNode {

    open var minHeight: CGFloat {
        return 64.0
    }
    
    open var maxHeight: CGFloat {
        return 200.0
    }
    
    open var maxStretch: CGFloat {
        return 60.0
    }
    
    public override init() {
        super.init()
        automaticallyManagesSubnodes = true
        automaticallyRelayoutOnSafeAreaChanges = true
        automaticallyRelayoutOnLayoutMarginsChanges = true
        setup()
    }
    
    private func setup() {
        style.width = ASDimension(unit: .fraction, value: 1.0)
    }
    
    open func setCollapseProgress(_ progress: CGFloat, animated: Bool) {}
}

