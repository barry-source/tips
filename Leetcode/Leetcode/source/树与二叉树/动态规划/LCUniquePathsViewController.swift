//
//  LCUniquePathsViewController.swift
//  Leetcode
//
//  Created by tongshichao on 2021/8/12.
//

import UIKit

class LCUniquePathsViewController: LCLinkBaseViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        print(uniquePaths(3, 7))
    }
    

    /*不同路径*/
    func uniquePaths(_ m: Int, _ n: Int) -> Int {
        var dp = Array(repeating: Array(repeating: 0, count: n), count: m)
        for i in 0..<m {
            for j in 0..<n {
                if i == 0 && j == 0 {
                    dp[0][0] = 1
                } else if i == 0 {
                    dp[i][j] = dp[i][j-1];
                } else if j == 0 {
                    dp[i][j] = dp[i-1][j];
                } else {
                    dp[i][j] = dp[i-1][j] + dp[i][j-1]
                }
            }
        }
        return dp[m - 1][n - 1]
    }

}
