//
//  ViewController.swift
//  kf_source
//
//  Created by user on 2023/5/17.
//

import UIKit
import Kingfisher

class ViewController: UIViewController {

    var imageView: UIImageView!
    var button: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        imageView = UIImageView()
        imageView.backgroundColor = .orange
        imageView.frame = CGRect(x: 0, y: 0, width: 100, height: 100)
        imageView.center = view.center
        
        button = UIButton(type: .custom)
        button.backgroundColor = .orange
        button.setTitle("加载", for: .normal)
        button.setTitleColor(.black, for: .normal)
        button.center = CGPoint(x: imageView.center.x, y: CGRectGetMaxY(imageView.frame) + 1)
        button.addTarget(self, action: #selector(buttonDidClick), for: .touchUpInside)
        
        [imageView, button].forEach(view.addSubview)
    }


    @objc func buttonDidClick() {
        let url = NSURL(string: "https://scpic.chinaz.net/files/default/imgs/2023-04-14/f9f163d1f77795df.jpg")
        imageView.kf.setImage(with: <#T##Source?#>, placeholder: <#T##Placeholder?#>, options: <#T##KingfisherOptionsInfo?#>, completionHandler: <#T##((Result<RetrieveImageResult, KingfisherError>) -> Void)?##((Result<RetrieveImageResult, KingfisherError>) -> Void)?##(Result<RetrieveImageResult, KingfisherError>) -> Void#>)
    }
}

