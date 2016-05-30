//
//  WebViewController.swift
//  TwitterClient02
//
//  Created by guest on 2016/05/13.
//  Copyright © 2016年 JEC. All rights reserved.
//

import UIKit
import WebKit

class WebViewController: UIViewController, WKNavigationDelegate {

    var toolBar: UIToolbar?
    var openURL = NSURL()
    var returnButton = UIBarButtonItem()
    var fastForwardButton = UIBarButtonItem()
    var refreshButton = UIBarButtonItem()
    var openInSafari = UIBarButtonItem()
    private var webView = WKWebView()
    private var progressView = UIProgressView()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        //WKWebViewのインスタンスの生成
        webView = WKWebView(frame: view.bounds, configuration: WKWebViewConfiguration())
        
        //デリゲートのこのビューコントローラを設定する
        webView.navigationDelegate = self
        
        // 横幅、高さ、ステータスバーの高さを取得する
        let width: CGFloat! = self.view.bounds.width
        let height: CGFloat! = self.view.bounds.height
//        let statusBarHeight: CGFloat! = UIApplication.sharedApplication().statusBarFrame.height
        
        // ツールバーを生成する
        toolBar = self.createToolBar(CGRectMake(0, height, width, 40.0), position: CGPointMake(width / 2, height - 20.0))
        
        //フリップでの戻る・進むを有効にする
        webView.allowsBackForwardNavigationGestures = true
        
        //WKWebViewインスタンスを画面に配置する
        view = webView
        // サブビューを追加する
        self.view.addSubview(self.toolBar!)
        
        //DetailViewControllerから引き渡されたURLを開く
        let request = NSURLRequest(URL: openURL)
        webView.loadRequest(request)
        
        // プログレスビューの生成、描画
        progressView = UIProgressView(progressViewStyle: UIProgressViewStyle.Bar)
        progressView.frame = CGRectMake(0, calcBarHeight(), view.bounds.size.width, 2)
        view.addSubview(progressView)
        
        // Webページ読み込みの監視スタート
        webView.addObserver(self, forKeyPath:"estimatedProgress", options:.New, context:nil)
        
        // 前のページに戻れるかどうか
        self.returnButton.enabled = self.webView.canGoBack
        // 次のページに進めるかどうか
        self.fastForwardButton.enabled = self.webView.canGoForward
        self.refreshButton.enabled = false
        self.openInSafari.enabled = false

    }
    deinit {
        webView.removeObserver(self, forKeyPath: "estimatedProgress")
    }
    
    // ツールバーを生成する
    func createToolBar(frame: CGRect, position: CGPoint) -> UIToolbar {
        // UIWebViewのインスタンスを生成
        let toolBarOption = UIToolbar()
        
        // ツールバーのサイズを決める.
        toolBarOption.frame = frame
        
        // ツールバーの位置を決める.
        toolBarOption.layer.position = position
        
        // 文字色を設定する
        toolBarOption.tintColor = UIColor.blueColor()
        // 背景色を設定する
        toolBarOption.backgroundColor = UIColor.whiteColor()
        
        // 各ボタンを生成する
        // UIBarButtonItem(style, デリゲートのターゲットを指定, ボタンが押されたときに呼ばれるメソッドを指定)
        let spacer: UIBarButtonItem = UIBarButtonItem(barButtonSystemItem: .FlexibleSpace, target: nil, action: nil)
        self.returnButton = UIBarButtonItem(barButtonSystemItem: .Rewind, target: self, action: #selector(WebViewController.back))
        self.fastForwardButton = UIBarButtonItem(barButtonSystemItem: .FastForward, target: self, action: #selector(WebViewController.forward))
        self.refreshButton = UIBarButtonItem(barButtonSystemItem: .Refresh, target: self, action: #selector(WebViewController.refresh))
        self.openInSafari = UIBarButtonItem(barButtonSystemItem: .Action, target: self, action: #selector(WebViewController.safari))
        
        // ボタンをツールバーに入れる.
        toolBarOption.items = [returnButton, fastForwardButton, refreshButton, spacer, openInSafari]
        
        return toolBarOption
    }
    
    
    // ビューが再レイアウトされるときに呼び出される
    override func viewWillLayoutSubviews() {
        let statusBarHeight: CGFloat! = UIApplication.sharedApplication().statusBarFrame.height
        self.webView.frame = CGRectMake(0, statusBarHeight, self.view.bounds.width, self.view.bounds.height)
    }
    
    // 戻るボタンの処理
    @IBAction func back(sender:AnyObject) {
        self.webView.goBack()
    }
    
    // 進むボタンの処理
    @IBAction func forward(sender:AnyObject) {
        self.webView.goForward()
    }
    
    // 再読み込みボタンの処理
    @IBAction func refresh(sender:AnyObject) {
        self.webView.reload()
    }
    
    // safari で開く
    @IBAction func safari(sender:AnyObject) {
        let url = self.webView.URL
        (UIApplication.sharedApplication() as? MyUIApplication)?.openSafari(url!)
    }
    
    override func viewDidAppear(animated: Bool) {
        progressView.frame = CGRectMake(0, calcBarHeight(), view.bounds.size.width, 2)
    }

    override func prefersStatusBarHidden() -> Bool { //横長でもステータスバーを表示したい場合false
        return false
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //**
    //** WKNavigationDelegate デリゲートメソッド
    //**
    func webView(webView: WKWebView,didStartProvisionalNavigation: WKNavigation) {
        startProcessing()
        
        self.returnButton.enabled = self.webView.canGoBack
        self.fastForwardButton.enabled = self.webView.canGoForward
        self.refreshButton.enabled = true
        self.openInSafari.enabled = true
    }
    
    func webView(webView: WKWebView, didFinishNavigation navigation: WKNavigation!) {
        progressView.progress = 0.0
        stopProcessing()
        
        self.returnButton.enabled = self.webView.canGoBack
        self.fastForwardButton.enabled = self.webView.canGoForward
        self.refreshButton.enabled = true
        self.openInSafari.enabled = true
    }
    
    func webView(webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!,
                 withError error: NSError) {
        progressView.progress = 0.0
        stopProcessing()
        print("Request Error: An error occurred while requeting: \(error)")
    }
    
    override func observeValueForKeyPath(keyPath:String?, ofObject object:AnyObject?, change:[String:AnyObject]?, context:UnsafeMutablePointer<Void>) { // 監視対象が変化したら
        switch keyPath! {
        case "estimatedProgress":
            if let progress = change![NSKeyValueChangeNewKey] as? Float {
                progressView.progress = progress
            }
        default:
            break
        }
    }

    //**
    //** インジケータ開始メソッド
    //**
    private func startProcessing() {
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
    }

    //**
    //** インジケータ停止メソッド
    //**
    private func stopProcessing() {
        UIApplication.sharedApplication().networkActivityIndicatorVisible = false
    }
    
    //**
    //** ステータスバー＆ナビゲーションバー高さ計算メソッド
    //**
    private func calcBarHeight() -> CGFloat {
        let statusBarHeight = UIApplication.sharedApplication().statusBarFrame.height
        let navigationBarHeight = navigationController?.navigationBar.frame.size.height ?? 0
        return statusBarHeight + navigationBarHeight
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
