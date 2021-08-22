//
//  LCValidParenthesesViewController.swift
//  Leetcode
//
//  Created by TSC on 2020/12/28.
//

import UIKit

class LCValidParenthesesViewController: LCLinkBaseViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        print(isValid("()"))
    }
    
    /*
     stack
     执行用时：4 ms, 在所有 Swift 提交中击败了96.05%的用户
     内存消耗：13.8 MB, 在所有 Swift 提交中击败了77.61%的用户
     */
    func isValid(_ s: String) -> Bool {
        if s.isEmpty { return true }
        if s.count % 2 != 0 { return false }
        let map: [Character: Character] = [")":"(","}":"{","]":"["]
        var stack: [Character] = []
        for c in s {
            if map.values.contains(c) {
                stack.append(c)
            } else {
                if stack.isEmpty { return false }
                let e = stack.removeLast()
                if e != map[c] {
                    return false
                }
            }
        }
        return stack.isEmpty
    }
//    func isValid(_ s: String) -> Bool {
//        if s.isEmpty { return true }
//        if s.count % 2 != 0 { return false }
//        var stack: [Character] = []
//        for c in s {
//            switch c {
//            case "(", "[", "{":
//                stack.append(c)
//            case ")":
//                if stack.count > 0, stack[stack.count - 1] == "(" {
//                    stack.removeLast()
//                } else {
//                    return false
//                }
//            case "]":
//                if stack.count > 0, stack[stack.count - 1] == "[" {
//                    stack.removeLast()
//                } else {
//                    return false
//                }
//            case "}":
//                if stack.count > 0, stack[stack.count - 1] == "{" {
//                    stack.removeLast()
//                } else {
//                    return false
//                }
//            default:
//                return false
//            }
//        }
//        return stack.isEmpty
//    }
    
    /*
     执行用时：880 ms, 在所有 Swift 提交中击败了10.37%的用户
     内存消耗：15.1 MB, 在所有 Swift 提交中击败了5.22%的用户
     */
//    func isValid(_ s: String) -> Bool {
//        if s.isEmpty { return true }
//        if s.count % 2 != 0 { return false }
//        var s = s
//        while s.contains("()") || s.contains("[]") || s.contains("{}") {
//            s = s.replacingOccurrences(of: "()", with: "")
//            s = s.replacingOccurrences(of: "[]", with: "")
//            s = s.replacingOccurrences(of: "{}", with: "")
//        }
//        return s.isEmpty
//    }
}
