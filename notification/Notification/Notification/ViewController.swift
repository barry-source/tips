//
//  ViewController.swift
//  Notification
//
//  Created by TSC on 2021/4/7.
//  Copyright © 2021 TSC. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    
    override func viewDidLoad() {
        super.viewDidLoad()
        syncPost()
        asyncPost()
    }

    
    private func syncPost() {
        NotificationCenter.default.addObserver(self, selector: #selector(syncNotification(noti:)), name: NSNotification.Name("sync"), object: nil)
    }
    
    private func asyncPost() {
        NotificationCenter.default.addObserver(self, selector: #selector(syncNotification(noti:)), name: NSNotification.Name("async"), object: nil)
    }
    
    @objc func syncNotification(noti: Notification) {
        print("Received")
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
//        NotificationCenter.default.post(Notification(name: NSNotification.Name("sync")))
        NotificationQueue.default.enqueue(Notification(name: Notification.Name("async")), postingStyle: .asap, coalesceMask: .none, forModes: nil)
        print("Posted")
    }
}

