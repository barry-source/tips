//
//  LCLargestRectangleAreaViewController.swift
//  Leetcode
//
//  Created by TSC on 2020/12/29.
//

import UIKit

class LCLargestRectangleAreaViewController: BaseViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

//        print(largestRectangleArea([2,1,5,6,2,3]))
    }
    

    /*
     固定高度暴力求解1: 超时
     执行用时：84 ms, 在所有 Swift 提交中击败了95.36%的用户
     内存消耗：14.7 MB, 在所有 Swift 提交中击败了83.33%的用户
     */
//    func largestRectangleArea(_ heights: [Int]) -> Int {
//        var maxValue = 0
//        for i in 0..<heights.count {
//            var left = i
//            var right = i
//            for l in (0..<i).reversed() {
//                if heights[l] < heights[i] {
//                    break
//                }
//                left = l
//            }
//            for r in i..<heights.count {
//                if heights[r] < heights[i] {
//                    break
//                }
//                right = r
//            }
//            maxValue = max((right - left + 1) * heights[i], maxValue)
//        }
//        return maxValue
//    }
    
    /*
     遍历宽度暴力求解1: 超时
     执行用时：84 ms, 在所有 Swift 提交中击败了95.36%的用户
     内存消耗：14.7 MB, 在所有 Swift 提交中击败了83.33%的用户
     */
//    func largestRectangleArea(_ heights: [Int]) -> Int {
//        var maxValue = 0
//        for i in 0..<heights.count {
//            var minHeight = heights[i]
//            for j in i..<heights.count {
//                minHeight = min(minHeight, heights[j])
//                maxValue = max(maxValue, (j - i + 1) * minHeight)
//            }
//        }
//        return maxValue
//    }
    
    /*
     stack求解1:
     执行用时：92 ms, 在所有 Swift 提交中击败了84.91%的用户
     内存消耗：14.4 MB, 在所有 Swift 提交中击败了70.59%的用户
     */
    func largestRectangleArea(_ heights: [Int]) -> Int {
        var heights = heights
        heights.append(0)
        var stack: [Int] = []
        var result = 0
        for i in heights.indices {
            while stack.count > 0 && heights[i] <= heights[stack.last!] {
                var span = i
                let height = heights[stack.removeLast()]
                if stack.count > 0 {
                    span = i - stack.last! - 1
                }
                result = max(result, span * height)
            }
            stack.append(i)
        }
        return result
    }

    
   
    
}
