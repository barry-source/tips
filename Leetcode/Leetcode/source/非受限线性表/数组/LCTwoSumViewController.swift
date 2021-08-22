//
//  LCTwoSumViewController.swift
//  Leetcode
//
//  Created by TSC on 2020/11/30.
//

import UIKit

class LCTwoSumViewController: BaseViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        print(twoSumDirectCaculating([3, 2, 6], 9))
        print(twoSum([3, 2, 6], 9))
    }
    
    // 暴力求解
    /*
     执行用时：48 ms, 在所有 Swift 提交中击败了46.41%的用户
     内存消耗：13.7 MB, 在所有 Swift 提交中击败了68.42%的用户
     */
    private func twoSumDirectCaculating(_ nums: [Int], _ target: Int) -> [Int] {
        for i in 0..<nums.count {
            for j in (i + 1)..<nums.count {
                if nums[i] + nums[j] == target {
                    return [i, j]
                }
            }
        }
        return []
    }

    // hash
    /*
     执行用时：44 ms, 在所有 Swift 提交中击败了66.23%的用户
     内存消耗：13.7 MB, 在所有 Swift 提交中击败了64.31%的用户
     */
    private func twoSum(_ nums: [Int], _ target: Int) -> [Int] {
        var map: [Int: Int] = [:]
        for (i, e) in nums.enumerated() {
            let reminder = target - e
            if let index = map[reminder], index != i  {
                return [index, i]
            }
            //因为是返回的下标，所以将下标作为value,
            map[e] = i
        }
        return []
    }

}



