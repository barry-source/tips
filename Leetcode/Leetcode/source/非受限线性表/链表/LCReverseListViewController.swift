//
//  LCReverseListViewController.swift
//  Leetcode
//
//  Created by TSC on 2020/12/22.
//

import UIKit

class LCReverseListViewController: LCLinkBaseViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let header = createList([1,2,3,4,5])
        let result = reverseList(header)
        printList(result)
    }
    

    
    /*
     循环求解
     执行用时：16 ms, 在所有 Swift 提交中击败了93.09%的用户
     内存消耗：14.2 MB, 在所有 Swift 提交中击败了71.90%的用户
     */
    
    func reverseList(_ head: ListNode?) -> ListNode? {
        var head = head
        var header: ListNode?
        while head != nil {
            let temp = header
            header = head
            head = head?.next
            header?.next = temp
        }
        return header
    }

    /*
     递归求解
     执行用时：16 ms, 在所有 Swift 提交中击败了93.09%的用户
     内存消耗：15.1 MB, 在所有 Swift 提交中击败了16.74%的用户
     */
//    func reverseList(_ head: ListNode?) -> ListNode? {
//        if head == nil || head?.next == nil {
//            return head
//        }
//        let temp = reverseList(head?.next)
//        printList(temp)
//        head?.next?.next = head
//        head?.next = nil
//        printList(head)
//        return temp
//    }
    
}
