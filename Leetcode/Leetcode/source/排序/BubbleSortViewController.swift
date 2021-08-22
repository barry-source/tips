//
//  BubbleSortViewController.swift
//  Leetcode
//
//  Created by tongshichao on 2021/8/13.
// https://www.cnblogs.com/onepixel/articles/7674659.html

import UIKit

class BubbleSortViewController: LCLinkBaseViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        print(bubbleSort([1,4,6,2,8]))
        
    }
    
    func bubbleSort(_ array: [Int]) -> [Int] {
        var array = array
        let len = array.count
        for i in array.indices {
            for j in 0 ..< len - 1 - i {
                if array[j] > array[j + 1] {
                    (array[j], array[j + 1]) = (array[j + 1], array[j])
                }
            }
        }
        return array
    }
    
}
