//
//  TestWindow.swift
//  ResponderChain
//
//  Created by tongshichao on 2025/12/6.
//

import UIKit

class TestWindow: UIWindow {

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        print("🧪 =======》\(self.tagName), Begin handling hitTest ")
        let view = super.hitTest(point, with: event)
        print("🧪《======= \(self.tagName), handing hitTest, result:", view?.tagName ?? "nil")
        return view
    }

    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        print("📍 ===》\(self.tagName), Begin handling pointInside")
        let inside = super.point(inside: point, with: event)
        print("📍《=== \(self.tagName), handing pointInside, result:", inside)
        return inside
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        print("🔥 \(self.tagName), handing touchesBegan in \(self.tagName)")
        super.touchesBegan(touches, with: event)
    }

    override func sendEvent(_ event: UIEvent) {
        print("🔥 \(self.tagName), handing sendEvent in \(self.tagName)")
        if let touches = event.allTouches {
            for touch in touches {
                if touch.phase == .began {
                    print("✅ First responder:", touch.view?.tagName)
                }
            }
        }
        
//        guard let touches = event.allTouches else { return }
//
//        for touch in touches {
//            if touch.phase == .began,
//               let view = touch.view {
//
//                print("🔥 sendEvent touch view =", view.tagName)
//
//                // ✅ 关键实验：如果第一次命中的是 ViewE，就把它隐藏
//                if view.tagName == "ViewE" {
//                    print("💥 动态隐藏 ViewE")
//                    view.isHidden = true
//                }
//            }
//        }
        super.sendEvent(event)
        
    }
}

