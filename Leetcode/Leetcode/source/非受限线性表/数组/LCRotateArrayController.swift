//
//  LCRotateArrayController.swift
//  Leetcode
//
//  Created by TSC on 2020/12/16.
//

import UIKit

class LCRotateArrayController: BaseViewController {

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
//        var nums = [1,2,3,4,5,6,7]
//        rotate(&nums, 2)
        var nums = [-1,-100,3,99]
        test(&nums, 2)
//        var nums = [1,2,3]
//        rotate(&nums, 2)
        print(nums)
    }
    
    /*
     数组反转
     执行用时：40 ms, 在所有 Swift 提交中击败了93.69%的用户
     内存消耗：15 MB, 在所有 Swift 提交中击败了28.57%的用户
     */
//    func rotate(_ nums: inout [Int], _ k: Int) {
//        let k = k % nums.count
//        if nums.count <= 1 {
//            return
//        }
//        reverse(&nums, 0, nums.count - 1)
//        reverse(&nums, 0, k - 1)
//        reverse(&nums, k, nums.count - 1)
//    }

//    func reverse(_ nums: inout [Int], _ start: Int, _ end: Int) {
//        var start = start
//        var end = end
//        while start < end {
//            (nums[start], nums[end]) = (nums[end], nums[start])
//            start += 1
//            end -= 1
//        }
//    }

    /*
     使用额外的数组求解
     执行用时：40 ms, 在所有 Swift 提交中击败了93.69%的用户
     内存消耗：15 MB, 在所有 Swift 提交中击败了20.00%的用户
     */
//    func rotate(_ nums: inout [Int], _ k: Int) {
//        var a: [Int] = [Int](repeating: 0, count: nums.count)
//        for i in 0..<nums.count {
//            a[(i + k) % nums.count] = nums[i]
//        }
//        for i in 0..<nums.count {
//            nums[i] = a[i]
//        }
//    }

    /*
     循环处理
     执行用时：44 ms, 在所有 Swift 提交中击败了69.37%的用户
     内存消耗：14.8 MB, 在所有 Swift 提交中击败了46.67%的用户
     */
    func rotate(_ nums: inout [Int], _ k: Int) {
        if nums.count == 0 { return }
        let k = k % nums.count
        var count = 0
        var start = 0
        while count < nums.count {
            var current = start
            var pre = nums[start]
            repeat {
                let next = (current + k) % nums.count
                (pre, nums[next]) = (nums[next], pre)
                current = next
                count += 1
            } while start != current
            start += 1
        }
        print(start)
    }
    
    /*
     暴力求解
     执行用时：3392 ms, 在所有 Swift 提交中击败了6.31%的用户
     内存消耗：14.9 MB, 在所有 Swift 提交中击败了37.14%%的用户
     */
//    func rotate(_ nums: inout [Int], _ k: Int) {
//        var pre = 0
//        for _ in 0..<k {
//            pre = nums[nums.count - 1]
//            for j in 0..<nums.count {
//                (pre, nums[j]) = (nums[j], pre)
//            }
//        }
//    }
}

extension LCRotateArrayController {
    func test(_ nums: inout [Int], _ k: Int) {
        if nums.count == 0 {
            return
        }
        let k = k % nums.count
        var count = 0
        var pre = 0
        var start = 0
        while count < nums.count {
            var current = start
            pre = nums[start]
            repeat {
                let next = (current + k) % nums.count
                (pre, nums[next]) = (nums[next], pre)
                count += 1
                current = next
            } while start != current
            start += 1
        }
    }
}
