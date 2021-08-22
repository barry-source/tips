//
//  PreviewViewController.swift
//  Leetcode
//
//  Created by TSC on 2020/12/1.
//

import UIKit
import HXPhotoPicker

class PreviewViewController: BaseViewController {

    private var model: CellModel
    private var datas: [PreviewModel]
    
    init(model: CellModel) {
        self.model = model
        self.datas = model.datas
        super.init()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(tableView)
        tableView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        setupRightBar()
    }
    
    private func setupRightBar() {

        let view = CGView(title: "LeedCode", frame: CGRect(x: 0, y: 0, width: 100, height: 50))
        let tap = UITapGestureRecognizer(target: self, action: #selector(leedcodeAction))
        view.addGestureRecognizer(tap)
        view.sizeToFit()
        if AppMode.shared.environmentType == .dev {
            let leedcode = UIBarButtonItem(customView: view)
            let barButtonItem = UIBarButtonItem(title: "测试", style: .done, target: self, action: #selector(test))
            navigationItem.rightBarButtonItems = [leedcode, barButtonItem]
        } else {
            let leedcode = UIBarButtonItem(customView: view)
            navigationItem.rightBarButtonItem = leedcode
        }
    }
    
    @objc private func test() {
        guard let name = model.destination, let vc = PreviewViewController.controllerFromString(controllerName: name) else { return }
        navigationController?.pushViewController(vc, animated: true)
    }
    
    @objc private func leedcodeAction() {
        guard let url = URL(string: model.detail) else { return }
        let vc = XZWebController(url: url)
        navigationController?.pushViewController(vc, animated: true)
    }
    
    
    lazy private var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .grouped)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.sectionHeaderHeight = UITableView.automaticDimension
        tableView.rowHeight = 56
        tableView.estimatedRowHeight = 56
        tableView.estimatedSectionHeaderHeight = 69
        tableView.separatorStyle = .none
        tableView.backgroundColor = .white
        tableView.register(PreviewCell.self, forCellReuseIdentifier: .cellId)
        tableView.register(PreviewHeaderView.self, forHeaderFooterViewReuseIdentifier: .headerViewId)
        return tableView
    }()

}

extension PreviewViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return datas.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: .cellId) as! PreviewCell
        cell.model = datas[indexPath.section]
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        guard let imageName = datas[indexPath.section].imageName else {
            return 0.01
        }
        if datas[indexPath.section].imageSize == .zero {
            let imageSize =  UIImage(named: imageName)?.size ?? .zero
            datas[indexPath.section].imageSize = imageSize
            datas[indexPath.section].cellHeight = getCellHeight(with: imageSize)
        }
        return datas[indexPath.section].cellHeight
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = tableView.dequeueReusableHeaderFooterView(withIdentifier: .headerViewId) as? PreviewHeaderView
        view?.model = datas[section]
        return view
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0.001
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return UIView()
    }
    
    private func getCellHeight(with imageSize: CGSize) -> CGFloat {
        if imageSize != .zero {
            return imageSize.height / imageSize.width * (UIScreen.main.screenWidth - 10) + 10
        }
        return 0
    }
    
}

extension PreviewViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let imageName = datas[indexPath.section].imageName, let image = UIImage(named: imageName) else {
            return
        }
        let model = HXCustomAssetModel.asset(withLocalImage: image, selected: true)
        let manager = HXPhotoManager(type: .photo)
        manager?.configuration.saveSystemAblum = true
        manager?.configuration.photoMaxNum = 0
        manager?.configuration.maxNum = 10
        manager?.configuration.selectTogether = true
        manager?.configuration.photoCanEdit = true
        manager?.configuration.previewRespondsToLongPress = { [weak self] (longPress, model, manager, controller) in
            
        }
        manager?.configuration.customPreviewFromView = { _ in
            return tableView.cellForRow(at: indexPath)
        }
        manager?.configuration.customPreviewToView = { _ in
            return tableView.cellForRow(at: indexPath)
        }
        manager?.addCustomAssetModel([model!])
        hx_presentPreviewPhotoController(with: manager, previewStyle: .dark, currentIndex: 0, photoView: nil)
    }
}

fileprivate extension String {
    static let cellId = "cellId"
    static let headerViewId = "headerViewId"
}

extension PreviewViewController {
    open class func controllerFromString(clsNameDefault: String = "", controllerName: String) -> UIViewController? {
        var clsName = ""
        if clsNameDefault.isEmpty {
            // 1.获取命名空间
            guard let clsNameSpace = Bundle.main.infoDictionary!["CFBundleExecutable"] as? String else { return nil }
            clsName = clsNameSpace
        } else {
            clsName = clsNameDefault
        }
        print(clsName)
        //生成控制器
        if let cls = NSClassFromString(controllerName) {
            // swift 中通过Class创建一个对象,必须告诉系统Class的类型
            guard let clsType = cls as? UIViewController.Type else { return nil }
            // 3.通过Class创建对象
            let childController = clsType.init()
            return childController
        } else {
            // 2.通过命名空间和类名转换成类
            let cls : AnyClass? = NSClassFromString((clsName) + "." + controllerName)
            // swift 中通过Class创建一个对象,必须告诉系统Class的类型
            guard let clsType = cls as? UIViewController.Type else { return nil }
            // 3.通过Class创建对象
            let childController = clsType.init()
            return childController
        }
    }
}


extension PreviewViewController {
    class CGView : UIView {
        
        private var title: String = ""
        
        init(title: String, frame: CGRect) {
            self.title = title
            // 必须设置一个frame，不设置或者设置约束都不行
            let frame = title.boundingRect(with: CGSize(width: 1000, height: 1000), options: .usesLineFragmentOrigin, attributes: [.font: UIFont.systemFont(ofSize: 18, weight: .semibold)], context: nil)
            super.init(frame: frame)
            setupUI()
        }
        
        override init (frame: CGRect) {
            super.init (frame: frame)
            setupUI()
        }
        
        required init ?(coder aDecoder: NSCoder ) {
            fatalError( "init(coder:) has not been implemented" )
        }
    
        override func layoutSubviews() {
            super.layoutSubviews()
        }
        
        private func setupUI() {
            addSubview(titleLabel)
            titleLabel.frame = bounds
            layer.insertSublayer(gradientLayer, at: 0)
            gradientLayer.frame = titleLabel.frame
            gradientLayer.mask = titleLabel.layer
        }
          
        private lazy var titleLabel: UILabel = {
            let label = UILabel()
            label.text = title
            label.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
            return label
        }()
        
        private lazy var gradientLayer: CAGradientLayer = {
            let gradientLayer = CAGradientLayer()
            gradientLayer.colors = [UIColor.red.cgColor, UIColor.green.cgColor]
            gradientLayer.locations = [0.0, 1.0]
            gradientLayer.startPoint = CGPoint.init(x: 0, y: 0.5)
            gradientLayer.endPoint = CGPoint.init(x: 1, y: 0.5)
            return gradientLayer
        }()
    }
}
