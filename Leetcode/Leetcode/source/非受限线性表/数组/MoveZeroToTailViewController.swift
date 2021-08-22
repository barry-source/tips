//
//  MoveZeroToTailViewController.swift
//  Leetcode
//
//  Created by TSC on 2020/12/7.
//

import UIKit

class MoveZeroToTailViewController: BaseViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        var nums = [0,1,0,3,12]
//        var nums = [2, 0, 0, 1]
        test(&nums)
        print(nums)
    }
    
    //暴利求解，时间复杂度O(n^2)
    /*
     执行用时：156 ms, 在所有 Swift 提交中击败了5.43%的用户
     内存消耗：14.2 MB, 在所有 Swift 提交中击败了50.69%的用户
     */
    func moveZeroes1(_ nums: inout [Int]) {
        for i in 0..<nums.count {
            if nums[nums.count - 1 - i] != 0 { continue }
            for j in (nums.count - i)..<nums.count {
                if nums[j] == 0 { break }
                (nums[j - 1], nums[j]) = (nums[j], nums[j - 1])
            }
            print(nums)
        }
    }
    
    // 索引求解，时间复杂度O(n)
    /*
     执行用时：44 ms, 在所有 Swift 提交中击败了96.61%的用户
     内存消耗：14.1 MB, 在所有 Swift 提交中击败了65.98%的用户
     */
    func moveZeroes(_ nums: inout [Int]) {
        // 记录最靠前零元素的位置，记录之后下次碰见非零元素交换位置
        var j = 0
        for i in 0..<nums.count {
            if nums[i] != 0 {
                nums[j] = nums[i]
                if i != j {
                    nums[i] = 0
                }
                j += 1
            }
        }
    }


}

extension MoveZeroToTailViewController {
    
    func test(_ nums: inout [Int]) {
        var j = 0
        for i in 0..<nums.count {
            if nums[i] == 0 {continue }
            if j != i {
                nums[j] = nums[i]
                nums[i] = 0
            }
            j += 1
        }
//        for i in 0..<nums.count {
//            if nums[nums.count - 1 - i] != 0 { continue }
//            for j in (nums.count - i) ..< nums.count {
//                if nums[j] == 0 { break }
//                (nums[j - 1], nums[j]) = (nums[j], nums[j - 1])
//            }
//        }
    }
}

//let count = nums.count
//for i in (0..<count).reversed() {
//    if nums[i] != 0 { continue }
//    for j in (i + 1)..<count {
//        if nums[j] == 0 { break }
//        (nums[j - 1], nums[j]) = (nums[j], nums[j - 1])
//    }
//}
