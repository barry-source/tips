//
//  LCCheckIPController.swift
//  Leetcode
//
//  Created by tongshichao on 2021/8/23.
//

import UIKit

class LCCheckIPController: BaseViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        print(ipToInteger("1.0.0.0"))
        // Do any additional setup after loading the view.
    }
    
    func checkIP(_ ip: String) -> Bool {
        // 1是否为空
        if ip.isEmpty { return false }
        // 2长度在7-15位之前（x.x.x.x-xxx.xxx.xxx.xxx）
        if ip.count < 7 || ip.count > 15 { return false }
        // 3首尾字符判断是否为.（.x.x.x或x.x.x.x.）
        if ip.first == "." || ip.last == "." { return false }
        // 4判断数组长度是否为4
        let ipComponent = ip.split(separator: ".")
        if ipComponent.count != 4 { return false }
        let ipInteger = ipComponent.compactMap { Int($0) }
        // 5判断每个元素的每个字符是否都是数字字符
        if ipInteger.count != 4 { return false }
        // 6判断第一个元素是否为0（0.xx.xx.xx不能成立）
        if ipInteger.first == 0 { return false }
        // 7 判断每个元素是否在0-255之间
        let result = ipInteger.contains { $0 > 255 || $0 < 0 }
        if result { return false}
        return true
    }
    
    func ipToInteger(_ ip: String) -> Int64 {
        if !checkIP(ip) { return 0 }
        let ipInteger = ip.split(separator: ".").compactMap { Int64($0)}
        var result: Int64 = 0
        for e in ipInteger {
            result = result << 8 + e
            print(result)
        }
        return result
    }
}
