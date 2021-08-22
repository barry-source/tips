//
//  LCMaxAreaViewController.swift
//  Leetcode
//
//  Created by TSC on 2020/12/11.
//

import UIKit

class LCMaxAreaViewController: BaseViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        print(maxArea2([1,8,6,2,5,4,8,3,7]))
        print(test([1,8,6,2,5,4,8,3,7]))
    }
    
    // 暴力求解
    /*
     超时
     */
    func maxArea1(_ height: [Int]) -> Int {
        var max = 0
        for i in 0..<height.count - 1 {
            for j in (i + 1)..<height.count {
                let temp = (j - i) * min(height[i], height[j])
                if temp > max {
                    max = temp
                }
            }
        }
        return max
    }
    
    // 左右夹壁
    /*
     执行用时：180 ms, 在所有 Swift 提交中击败了57.20%的用户
     内存消耗：14.3 MB, 在所有 Swift 提交中击败了24.61%的用户
     */
    func maxArea2(_ height: [Int]) -> Int {
        var maxArea = 0
        var left = 0
        var right = height.count - 1
        while left < right {
            var temp: Int
            if height[left] < height[right] {
                temp = (right - left) * height[left]
                left += 1
            } else {
                temp = (right - left) * height[right]
                right -= 1
            }
            maxArea = max(maxArea, temp)
        }
        return maxArea
    }
}

extension LCMaxAreaViewController {
    func test(_ height: [Int]) -> Int {
        var maxArea = 0
        
        var left = 0
        var right = height.count - 1
        while left < right {
            var temp = 0
            if height[left] > height[right] {
                temp = (right - left) * height[right]
                right -= 1
            } else {
                temp = (right - left) * height[left]
                left += 1
            }
            maxArea = max(maxArea, temp)
        }
        return maxArea
    }
}
