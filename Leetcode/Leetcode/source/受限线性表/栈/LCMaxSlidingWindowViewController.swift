//
//  LCMaxSlidingWindowViewController.swift
//  Leetcode
//
//  Created by TSC on 2020/12/30.
//

import UIKit

class LCMaxSlidingWindowViewController: BaseViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        print(maxSlidingWindow([1,-1], 1))
        
    }
    

    func maxSlidingWindow(_ nums: [Int], _ k: Int) -> [Int] {
        var queue = [Int]()
        var result = [Int]()
        let length = nums.count
        for i in 0..<length {
            while (queue.count > 0 && nums[i] > nums[queue.last!]) {
                queue.removeLast()
            }
            queue.append(i)
            
            let w = i - k + 1
            if w >= 0 {
                if w > queue.first! {
                    queue.removeFirst()
                }
                result.append(nums[queue.first!])
            }
        }
        return result
    }

}
