//
//  LCDeleteSortedDuplicateNumberController.swift
//  Leetcode
//
//  Created by TSC on 2020/12/15.
//

import UIKit

class LCDeleteSortedDuplicateNumberController: BaseViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        var array = [0,0,1,1,1,2,2,3,3,4]
//        var array = [1,1,1,1,1,1]
//        var array = [0,1,2,3,4,5,6,7,8,9]
        print(test(&array))
        print(array)
    }
    
    // 暴力求解
    /*
     执行用时：96 ms, 在所有 Swift 提交中击败了33.81%的用户
     内存消耗：14.4 MB, 在所有 Swift 提交中击败了49.76%的用户
     */
    func removeDuplicates1(_ nums: inout [Int]) -> Int {
        var currentIndex = 0
        var length = nums.count
        while currentIndex < length {
            let j = currentIndex + 1
            while j < length, nums[j] == nums[currentIndex] {
                nums.remove(at: j)
                length -= 1
            }
            currentIndex += 1
        }
        return length
    }
    
    // 双指针求解
    /*
     执行用时：76 ms, 在所有 Swift 提交中击败了93.14%的用户
     内存消耗：14.6 MB, 在所有 Swift 提交中击败了24.88%的用户
     */
    func removeDuplicates(_ nums: inout [Int]) -> Int {
        if nums.count == 0 { return 0 }
        var i = 0
        for j in 1..<nums.count {
            if (nums[j] != nums[i]) {
                i += 1
                nums[i] = nums[j]
            }
        }
        return i + 1
    }
    
//    func removeDuplicates(_ nums: inout [Int]) -> Int {
//        if nums.count == 0 { return 0 }
//        var currentIndex = 0
//        for j in (currentIndex + 1)..<nums.count {
//            if nums[currentIndex] != nums[j] {
//                currentIndex += 1
//                nums[currentIndex] = nums[j]
//            }
//        }
//        return currentIndex + 1
//    }
}

extension LCDeleteSortedDuplicateNumberController {
    func test(_ nums: inout [Int]) -> Int {
        
        if nums.count <= 1 { return nums.count }
        
        var slow = 0
        for j in 1..<nums.count {
            if nums[slow] != nums[j] {
                slow += 1
                nums[slow] = nums[j]
            }
        }
        return slow + 1
//        if nums.count == 0 {
//            return 0
//        }
//        var currentIndex = 0
//        var length = nums.count
//        while currentIndex < length {
//            let j = currentIndex + 1
//            while j < length, nums[j] == nums[currentIndex]  {
//                nums.remove(at: j)
//                length -= 1
//            }
//            currentIndex += 1
//        }
//
//        return length
    }
}
