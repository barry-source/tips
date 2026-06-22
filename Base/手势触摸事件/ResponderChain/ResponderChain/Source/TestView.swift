//
//  TestView.swift
//  ResponderChain
//
//  Created by tongshichao on 2025/12/6.
//

import UIKit

class TestView: UIView {

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        print("🧪 =======》\(self.tagName), Begin handling hitTest")
        let view = super.hitTest(point, with: event)
        print("🧪《======= \(self.tagName), handling hitTest, result:", view?.tagName ?? "nil")
        return view
    }

    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        print("📍 ===》\(self.tagName), Begin handling pointInside")
        let inside = super.point(inside: point, with: event)
        print("📍《=== \(self.tagName), handling pointInside \(self.tagName):", inside)
        return inside
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        print("🔥 \(self.tagName), handling touchesBegan in \(self.tagName)")
        super.touchesBegan(touches, with: event)
    }

}

extension UIView {
    var tagName: String {
        return accessibilityIdentifier ?? "unknown"
    }
}
