//
//  LCThreeSumViewController.swift
//  Leetcode
//
//  Created by TSC on 2020/12/2.
//

import UIKit

class LCThreeSumViewController: BaseViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        print(threeSum1([-1, 0, 1, 2, -1, -4]))
        print(threeSum2([-1, 0, 1, 2, -1, -4]))
        print(threeSum3([1,-1,-1,0]))
        
        print(test([-1, 0, 1, 2, -1, -4]))
        
        
    }

        
    /*
     执行用时：244 ms, 在所有 Swift 提交中击败了93.08%的用户
     内存消耗：17.5 MB, 在所有 Swift 提交中击败了60.69%的用户
     */
    // 双指针法
    private func threeSum1(_ nums: [Int]) -> [[Int]] {
        guard nums.count >= 3 else { return [] }
        var result: [[Int]] = []
        let sorted = nums.sorted()
        for i in 0..<sorted.count - 2 {
            // 最小的数大于0
            if sorted[i] > 0 { break }
            // 除去target重复元素
            if i != 0 && sorted[i] == sorted[i - 1] { continue }
            var left = i + 1
            var right = sorted.count - 1
            let target = -sorted[i]
            while left < right {
                if sorted[left] + sorted[right] == target {
                    result.append([-target, sorted[left], sorted[right]])
                    // 除去两端重复元素
                    repeat {
                        left += 1
                    } while left < right && sorted[left] == sorted[left - 1]
                    repeat {
                        right -= 1
                    } while left < right && sorted[right] == sorted[right + 1]
                } else if sorted[left] + sorted[right] > target {
                    right -= 1
                } else if sorted[left] + sorted[right] < target {
                    left += 1
                }
            }
        }
        return result
    }
    
    /*
     执行用时：4220 ms, 在所有 Swift 提交中击败了5.03%的用户
     内存消耗：18 MB, 在所有 Swift 提交中击败了15.41%的用户
     */
    // O(n^2), 两数之和变形
    private func threeSum2(_ nums: [Int]) -> [[Int]] {
        var result: [[Int]] = []
        var map: [Int: Int] = [:]
        var resultSet: Set<Set<Int>> = []
        for i in 0..<nums.count {
            map[nums[i]] = i
        }
        for i in 0..<nums.count {
            for j in (i + 1)..<nums.count {
                let target = -(nums[i] + nums[j])
                // idx需要大于j,因为不能取重复的元素
                if let idx = map[target], idx > j, !resultSet.contains([nums[i], nums[j], target]) {
                    result.append([nums[i], nums[j], target])
                    resultSet.insert([nums[i], nums[j], target])
                }
            }
        }
        return result
    }
    
    // 暴力求解，超时
    private func threeSum3(_ nums: [Int]) -> [[Int]] {
        var result: [[Int]] = []
        var resultSet: Set<Set<Int>> = []
        for i in 0..<nums.count {
            for j in i + 1..<nums.count {
                for k in j + 1..<nums.count {
                    if nums[i] + nums[j] + nums[k] == 0 {
                        if !resultSet.contains([nums[i], nums[j], nums[k]]) {
                            result.append([nums[i], nums[j], nums[k]])
                            resultSet.insert([nums[i], nums[j], nums[k]])
                        }
                    }
                }
            }
        }
        return result
    }

}






extension LCThreeSumViewController {
    
    
    private func test(_ nums: [Int]) -> [[Int]] {
        guard nums.count >= 3 else {
            return []
        }
        var result: [[Int]] = []
        let sortedArray: [Int] = nums.sorted()
        for i in 0..<sortedArray.count - 2 {
            if sortedArray[i] > 0 {
                break
            }
            if i != 0, sortedArray[i] == sortedArray[i - 1] {
                continue
            }
            var left = i + 1
            var right = sortedArray.count - 1
            while left < right {
                if sortedArray[i] + sortedArray[left] + sortedArray[right] == 0 {
                    result.append([sortedArray[i], sortedArray[left], sortedArray[right]])
                    repeat {
                        left += 1
                    } while sortedArray[left] == sortedArray[left - 1] && left < right
                    repeat {
                        right -= 1
                    } while sortedArray[right] == sortedArray[right + 1] && left < right
                } else if sortedArray[i] + sortedArray[left] + sortedArray[right] > 0 {
                    right -= 1
                } else if sortedArray[i] + sortedArray[left] + sortedArray[right] < 0 {
                    left += 1
                }
            }
        }
        return result
    }
    
}
