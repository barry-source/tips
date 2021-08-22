//
//  QuickSortViewController.swift
//  Leetcode
//
//  Created by tongshichao on 2021/8/14.
//

import UIKit

class QuickSortViewController: LCLinkBaseViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

//        var array = [4,1,2,8, 9]
//        var array = [2,6,9,4,8, 1]
        var array = [49,38,65,97,76, 13, 27]
//        var array = [438,27]
        quickSort(list: &array, low: 0, high: array.count - 1)
        print(array)
    }

    func quickSort(list: inout [Int], low: Int, high: Int) {
        if low > high { return }
        var (iLow, iHigh) = (low, high)
        let priot = list[low]
        print("priot: \(priot)")
        while iLow != iHigh {
            while iLow < iHigh && list[iHigh] >= priot {
                iHigh -= 1
            }
            while iLow < iHigh && list[iLow] <= priot {
                iLow += 1
            }
            if iLow < iHigh {
                (list[iLow], list[iHigh]) = (list[iHigh], list[iLow])
            }
            print(list)
        }
        
        list[low] = list[iLow]
        list[iLow] = priot
        print(list)
        print("-------------")
        quickSort(list: &list, low: low, high: iLow - 1)
        quickSort(list: &list, low: iLow + 1, high: high)
    }
}
