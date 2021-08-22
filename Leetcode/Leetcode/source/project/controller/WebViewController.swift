//
//  WebViewController.swift
//  Leetcode
//
//  Created by TSC on 2020/11/30.
//

import UIKit
import WebKit
import HXPhotoPicker

class XZWebController: BaseViewController {
    
    private var titleObservation: NSKeyValueObservation?
    private var progressObservation: NSKeyValueObservation?
    private let request: URLRequest
    
    // MARK: - Init & Deinit
    deinit {
        titleObservation?.invalidate()
        progressObservation?.invalidate()
    }
    
    init(url: URL) {
        request = URLRequest(url: url)
        super.init()
    }
    
    init(_ request: URLRequest) {
        self.request = request
        super.init()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    public override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        webView.load(request)
    }
    
    // MARK: - UI
    private func setupUI() {
        view.addSubview(webView)
        view.addSubview(progressView)
        webView.snp.makeConstraints { (maker) in
            maker.leading.trailing.bottom.equalTo(view)
            maker.top.equalTo(view.snp_topMargin)
        }
        progressView.snp.makeConstraints { (maker) in
            maker.top.equalTo(view.snp_topMargin)
            maker.leading.trailing.equalTo(view)
            maker.height.equalTo(2)
        }
    }
    
    // MARK: - Networks
    
    // MARK: - Private
    
    // MARK: - Notifications
    
    // MARK: - Lazy load
    open lazy var webView: WKWebView = {
        let configuration = WKWebViewConfiguration()
        configuration.mediaTypesRequiringUserActionForPlayback = []
        configuration.allowsInlineMediaPlayback = true
        let webView = WKWebView(frame: .zero, configuration: configuration)
        titleObservation = webView.observe(\.title) { [weak self] (webView, changed) in
            guard let self = self else { return }
            self.navigationItem.title = webView.title
        }
        progressObservation = webView.observe(\.estimatedProgress) { [weak self] (webView, changed) in
            guard let self = self else { return }
            self.progressView.alpha = 1.0
            self.progressView.progress = Float(self.webView.estimatedProgress)
            if self.webView.estimatedProgress >= 1.0 {
                UIView.animate(withDuration: 0.3, delay: 0.1, options: .curveEaseOut, animations: {
                    self.progressView.alpha = 0
                }, completion: { (finish) in
                    self.progressView.setProgress(0.0, animated: false)
                })
            }
        }
        
        return webView
    }()
    
    // 暂时非全屏添加进度条
    lazy private var progressView: UIProgressView = {
        let progressView = UIProgressView(frame: CGRect(x: 0, y: 1, width: UIScreen.main.bounds.width, height: 1.5))
        progressView.tintColor = UIColor(red: 0xff / 255.0, green: 0xcc / 255.0, blue: 0x43 / 255.0, alpha: 1)
        progressView.trackTintColor = UIColor.white
        return progressView
    }()
    
}
