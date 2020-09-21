//
//  StickyHeaderNode.swift
//  Pods
//
//  Created by Daniel Hariri on 21.09.20.
//

import AsyncDisplayKit

public class StickyHeaderNode: ASDisplayNode {

    public var minHeight: CGFloat {
        return 64.0
    }
    
    public var maxHeight: CGFloat {
        return 200.0
    }
    
    public var maxStretch: CGFloat {
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
    
    public func setCollapseProgress(_ progress: CGFloat, animated: Bool) {}
}

