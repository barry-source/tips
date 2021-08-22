//
//  LCUniquePaths2ViewController.swift
//  Leetcode
//
//  Created by tongshichao on 2021/8/12.
//

import UIKit

class LCUniquePaths2ViewController: LCLinkBaseViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        print(uniquePathsWithObstacles([[0,0,0],[0,1,0],[0,0,0]]))
    }
    

    /*不同路径2*/
    // 这个和下面的是反着来的
    func uniquePathsWithObstacles(_ obstacleGrid: [[Int]]) -> Int {
        let m = obstacleGrid.count
        guard m != 0 else{
            return 0
        }
        let n = obstacleGrid[0].count
        //    空间优化O(N)
        var dp = [Int](repeating: 0, count: n + 1)
        dp[n-1] = 1
        for i in (0..<m).reversed()  {//
            for j in (0..<n).reversed()  {//
                if obstacleGrid[i][j] == 1 {
                    dp[j] = 0
                } else{
                    dp[j] = dp[j] + dp[j+1]
                }
            }
        }
        return dp[0]
    }
    
    // 效率高
    func uniquePathsWithObstacles2(_ obstacleGrid: [[Int]]) -> Int {

        if obstacleGrid[0][0] == 1 { return 0 }
        var dp = Array(repeating: Array(repeating: 0, count: obstacleGrid[0].count), count: obstacleGrid.count)
        for i in 0..<obstacleGrid.count {
            for j in 0..<obstacleGrid[0].count {
                if i == 0 && j == 0 {
                    dp[0][0] = 1
                } else if i == 0 {
                    dp[i][j] = obstacleGrid[i][j] == 1 ? 0 : dp[i][j-1];
                } else if j == 0 {
                    dp[i][j] = obstacleGrid[i][j] == 1 ? 0 : dp[i-1][j];
                } else {
                    dp[i][j] = obstacleGrid[i][j] == 1 ? 0 : dp[i-1][j] + dp[i][j-1]
                }
            }
        }
        print(dp)
        return dp.last!.last!
    }

}
