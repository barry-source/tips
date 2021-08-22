//
//  ViewController.swift
//  Leetcode
//
//  Created by TSC on 2020/11/27.
//https://www.sojson.com/

import UIKit

class ViewController: UIViewController {

    private lazy var datas: [SectionModel] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(red: 0xf7 / 255.0, green: 0xf8 / 255.0, blue: 0xfa / 255.0, alpha: 1)
        view.addSubview(tableView)
        tableView.frame = view.bounds
        let path = Bundle.main.path(forResource: "datas", ofType: "json")
        let url = URL(fileURLWithPath: path!)
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            datas = try decoder.decode([SectionModel].self, from: data)
            for i in 0..<datas.count {
                datas[i].datas[0].first = true
                datas[i].datas[datas[i].datas.count - 1].last = true
            }
            print(datas)
        } catch (_) {
            print("解析出错")
        }
        
    }
    
    lazy private var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .grouped)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.sectionHeaderHeight = 69
        tableView.backgroundColor = UIColor(red: 0xf7 / 255.0, green: 0xf8 / 255.0, blue: 0xfa / 255.0, alpha: 1)
        tableView.rowHeight = 56
        tableView.separatorStyle = .none
        tableView.register(LCTableViewCell.self, forCellReuseIdentifier: .cellId)
        tableView.register(LCTableViewHeaderView.self, forHeaderFooterViewReuseIdentifier: .headerViewId)
        return tableView
    }()
}

extension ViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return datas.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return datas[section].datas.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: .cellId) as! LCTableViewCell
        cell.data = datas[indexPath.section].datas[indexPath.row]
        return cell
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = tableView.dequeueReusableHeaderFooterView(withIdentifier: .headerViewId) as? LCTableViewHeaderView
        view?.model = datas[section]
        return view
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0.001
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return UIView()
    }

}

extension ViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let model = datas[indexPath.section].datas[indexPath.row]
        let vc = PreviewViewController(model: model)
        vc.title = model.title
        navigationController?.pushViewController(vc, animated: true)
//        let vc = LCThreeSumViewController()
//        navigationController?.pushViewController(vc, animated: true)
    }
}

struct SectionModel: Codable {
    var title: String?
    var datas: [CellModel] = []
}

struct CellModel: Codable {
    var first: Bool = false  //指示是否第一个Cell
    var last: Bool = false  //指示是否最后一个Cell
    var title: String?
    var datas: [PreviewModel] = []
    var destination: String?
    var detail: String = "https://www.baidu.com" // h5链接
    
    enum CodingKeys: String, CodingKey {
        case title
        case datas
        case destination
        case detail
    }
}

fileprivate extension String {
    static let cellId = "cellId"
    static let headerViewId = "headerViewId"
}

