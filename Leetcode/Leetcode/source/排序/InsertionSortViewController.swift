//
//  InsertionSortViewController.swift
//  Leetcode
//
//  Created by tongshichao on 2021/8/14.
// https://www.cnblogs.com/onepixel/articles/7674659.html

import UIKit

class InsertionSortViewController: LCLinkBaseViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        print(insertionSort([1,4,6,2,8]))
    }
    


    func insertionSort(_ array: [Int]) -> [Int] {
        var array = array
        let len = array.count
        for i in 1 ..< len {
            var currentIndex = i
            let temp = array[i]
            while currentIndex > 0 && temp < array[currentIndex - 1] {
                array[currentIndex] = array[currentIndex - 1]
                currentIndex -= 1
            }
            array[currentIndex] = temp
        }
        return array
    }

}
