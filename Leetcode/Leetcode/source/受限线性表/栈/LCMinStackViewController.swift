//
//  LCMinStackViewController.swift
//  Leetcode
//
//  Created by TSC on 2020/12/29.
//

import UIKit

class LCMinStackViewController: BaseViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
}

/*
 使用stack
 执行用时：88 ms, 在所有 Swift 提交中击败了82.12%的用户
 内存消耗：14.9 MB, 在所有 Swift 提交中击败了46.00%的用户
 */

//class MinStack {
//
//    private var stack: [Int] = []
//    private var minStack: [Int] = []
//
//    init() {
//    }
//
//    func push(_ x: Int) {
//        stack.append(x)
//        if minStack.count == 0 {
//            minStack.append(x)
//        } else {
//            let min = minStack[minStack.count - 1]
//            if min < x {
//                minStack.append(min)
//            } else {
//                minStack.append(x)
//            }
//        }
//    }
//
//    func pop() {
//        stack.removeLast()
//        minStack.removeLast()
//    }
//
//    func top() -> Int {
//        if stack.count == 0 { return -1 }
//        return stack[stack.count - 1]
//    }
//
//    func getMin() -> Int {
//        if stack.count == 0 { return -1 }
//        return minStack[minStack.count - 1]
//    }
//}


/*
 不使用stack
 执行用时：84 ms, 在所有 Swift 提交中击败了95.36%的用户
 内存消耗：14.7 MB, 在所有 Swift 提交中击败了83.33%的用户
 */
class MinStack {
    
    var minValue = 0
    var stack: [Int] = []
    
    func push(_ x: Int) {
        if stack.isEmpty {
            stack.append(0)
            minValue = x
        } else {
            stack.append(x - minValue)
            if x < minValue {
                minValue = x
            }
        }
    }
    
    func pop() {
        if stack.isEmpty { return }
        let pop = stack.removeLast()
        if pop < 0 {
            minValue -= pop
        }
    }
    
    func top() -> Int {
        guard let top = stack.last else { return .max }
        return top > 0 ? top + minValue : minValue
    }
    
    func getMin() -> Int {
        return minValue
    }
}
