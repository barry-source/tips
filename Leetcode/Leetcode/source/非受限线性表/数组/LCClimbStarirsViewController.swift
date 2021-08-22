//
//  LCClimbStarirsViewController.swift
//  Leetcode
//
//  Created by TSC on 2020/12/14.
//

import UIKit

class LCClimbStarirsViewController: BaseViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        print(climbStairs(100))
    }
    
    // 斐波那契求解
    /*
     执行用时：4 ms, 在所有 Swift 提交中击败了71.95%的用户
     内存消耗：13.4 MB, 在所有 Swift 提交中击败了44.44%的用户
     */
    func climbStairs(_ n: Int) -> Int {
        if n <= 2 {
            return n
        }
        var f1 = 1
        var f2 = 2
        for _ in 2..<n {
            (f1, f2) = (f2, f1 + f2)
        }
        return f2
    }

//    // 递归求解
//    /*超时
//     */
//    func climbStairs(_ n: Int) -> Int {
//        return climb(n)
//    }
//
//    func climb(_ n: Int) -> Int {
//        if n <= 2 {
//            return n
//        } else {
//            return climb(n - 1) + climb(n - 2)
//        }
//    }

    
//    // 递归求解 缓存中间结果
//    /*
//      执行用时：4 ms, 在所有 Swift 提交中击败了71.95%的用户
//      内存消耗：13.6 MB, 在所有 Swift 提交中击败了12.46%的用户
//     */
//    private var cache: [Int : Int] = [1: 1, 2: 2, 3: 3]
//
//    func climbStairs(_ n: Int) -> Int {
//        return climb(n)
//    }
//
//    func climb(_ n: Int) -> Int {
//        if let result = cache[n] {
//            return result
//        }
//        let temp = climb(n - 1) + climb(n - 2)
//        cache[n] = temp
//        return temp
//    }
}
