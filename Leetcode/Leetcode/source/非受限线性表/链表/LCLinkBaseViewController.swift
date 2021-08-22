//
//  LCLinkBaseViewController.swift
//  Leetcode
//
//  Created by TSC on 2020/12/23.
//

import UIKit

public class TreeNode {
    public var val: Int
    public var left: TreeNode?
    public var right: TreeNode?
    public init() {
        self.val = 0
    }
    public init(_ val: Int) {
        self.val = val
    }
    public init(_ val: Int, _ left: TreeNode?, _ right: TreeNode?) {
        self.val = val
        self.left = left
        self.right = right
    }
}

public class ListNode {
    public var val: Int
    public var next: ListNode?
    public init(_ val: Int) {
        self.val = val
        self.next = nil
    }
}

class LCLinkBaseViewController: BaseViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
//        view.translatesAutoresizingMaskIntoConstraints
        // Do any additional setup after loading the view.
    }

    func createList(_ array: [Int]) -> ListNode? {
        if array.count == 0 {
            return nil
        }
        var header: ListNode?
        var temp: ListNode?
        for i in 1...array.count {
            if i == 1 {
                header = ListNode(i)
                header?.val = i
                temp = header
            } else {
                temp?.next = ListNode(i)
                temp = temp?.next
                temp?.val = i
            }
        }
        temp?.next = nil
        return header
    }
    
    func createList1(_ array: [Int]) -> (ListNode?, ListNode?) {
        if array.count == 0 {
            return (nil, nil)
        }
        var header: ListNode?
        var temp: ListNode?
        for i in 1...array.count {
            if i == 1 {
                header = ListNode(array[i - 1])
                header?.val = array[i - 1]
                temp = header
            } else {
                temp?.next = ListNode(array[i - 1])
                temp = temp?.next
                temp?.val = array[i - 1]
            }
        }
        temp?.next = nil
        return (header, temp)
    }
    
    
    func createBinaryTree(_ array: [AnyObject]) -> TreeNode? {
        if array.count == 0 {
            return nil
        }
        
        return nil
    }
    
    
    func printList(_ head: ListNode?) {
        if head == nil {
            print("-----------------")
            return
        }
        var head: ListNode? = head
        repeat {
            print(head?.val ?? -1)
            head = head?.next
        } while head?.next != nil
        print(head?.val ?? -1)
        print("-----------------")
    }

}
