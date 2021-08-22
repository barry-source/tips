//
//  HeapSortViewController.swift
//  Leetcode
//
//  Created by tongshichao on 2021/8/14.
//

import UIKit

class HeapSortViewController: LCLinkBaseViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
//        var array = [2,6,9,4,8, 1]
        var array = [4,6,8,5,9]
        heapSort(array: &array)
        print(array)
    }
    
    func heapSort(array: inout [Int]) {
        for i in (0..<array.count / 2).reversed() {
            adjustHeap(array: &array, index: i, length: array.count)
        }
        for i in (1..<array.count).reversed() {
            (array[0], array[i]) = (array[i], array[0])
            adjustHeap(array: &array, index: 0, length: i)
        }
    }
    
    func adjustHeap(array: inout [Int], index: Int, length: Int) {
        var i = index
        let oldTop = array[index]
        var childLeft = index * 2 + 1
        
        while childLeft < length {
            if childLeft + 1 < length && array[childLeft] < array[childLeft + 1] {
                childLeft += 1
            }
            if array[childLeft] > oldTop {
                array[i] = array[childLeft]
                i = childLeft
            } else {
                break
            }
            childLeft = childLeft * 2 + 1
        }
        array[i] = oldTop
    }

}
