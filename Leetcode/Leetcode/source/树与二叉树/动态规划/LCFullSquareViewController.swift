//
//  LCFullSquareViewController.swift
//  Leetcode
//
//  Created by tongshichao on 2021/8/11.
//

import UIKit

class LCFullSquareViewController: LCLinkBaseViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        print(numSquares(13))
        
    }
    

    /*平方数*/
    func numSquares(_ n: Int) -> Int {
        var dp = [Int](repeating: Int.max, count: n+1)
        dp[0] = 0
        
        for i in 1...n {
          for j in 1...i {
            let s = j * j
            if s > i { break }
            dp[i] = min(dp[i], dp[i-s] + 1)
          }
        }
        //本来就非常耗时，加上where之后leetcode就超时了
//
//        for i in 1...n {
//          for j in 1...i where i >= j * j {
//            dp[i] = min(dp[i], dp[i - j * j] + 1)
//          }
//        }
        
        
        return dp.last!
    }

}
