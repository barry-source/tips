//
//  LCPlusOneViewController.swift
//  Leetcode
//
//  Created by TSC on 2020/12/22.
//

import UIKit

class LCPlusOneViewController: BaseViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        let digits = [1,2,3]
//        let digits = [9,9,9]
        print(plusOne(digits))
        // Do any additional setup after loading the view.
    }
    
    /*
     直接处理数组
     执行用时：4 ms, 在所有 Swift 提交中击败了98.23%的用户
     内存消耗：13.6 MB, 在所有 Swift 提交中击败了44.14%的用户
     */
    func plusOne(_ digits: [Int]) -> [Int] {
        var digits = digits
        var plus = false
        for i in (0..<digits.count).reversed() {
            if plus || digits.count - 1 == i {
                if digits[i] + 1 >= 10 {
                    digits[i] = (digits[i] + 1) % 10
                    plus = true
                } else {
                    plus = false
                    digits[i] += 1
                }
            }
        }
        if plus {
            digits.insert(0, at: 0)
            digits[0] = 1
//            digits.append(0)
//            for i in (1..<digits.count - 1).reversed() {
//                digits[i + 1] = digits[i]
//            }
//            digits[0] = 1
        }
        return digits
    }

}
