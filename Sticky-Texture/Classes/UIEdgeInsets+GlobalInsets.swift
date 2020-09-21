//
//  UIEdgeInsets+GlobalInsets.swift
//  Pods
//
//  Created by Daniel Hariri on 21.09.20.
//

import UIKit

extension UIEdgeInsets {
    static var globalSafeAreaInsets: UIEdgeInsets {
        let keyWindow = UIApplication.shared.connectedScenes
            .filter({$0.activationState == .foregroundActive})
            .map({$0 as? UIWindowScene})
            .compactMap({$0})
            .first?.windows
            .filter({$0.isKeyWindow}).first
        return keyWindow?.safeAreaInsets ?? .zero
    }
}

