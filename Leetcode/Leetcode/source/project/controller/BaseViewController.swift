//
//  BaseViewController.swift
//  Leetcode
//
//  Created by TSC on 2020/11/30.
//

import UIKit

class BaseViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .white
        setBackBarButtonItem()
    }
    
    init() {
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func goBack() {
        navigationController?.popViewController(animated: true)
    }
    
    private func setBackBarButtonItem() {
        let image = UIImage(named: "xz_ic_back_gray")?.withRenderingMode(.alwaysOriginal)
        let barButtonItem = UIBarButtonItem(image: image, style: .plain, target: self, action: #selector(goBack))
        navigationItem.leftBarButtonItem = barButtonItem
    }

}
