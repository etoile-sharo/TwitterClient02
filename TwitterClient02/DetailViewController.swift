//
//  DetailViewController.swift
//  TwitterClient02
//
//  Created by guest on 2016/05/09.
//  Copyright © 2016年 JEC. All rights reserved.
//

import UIKit
import Accounts
import Social

class DetailViewController: UIViewController {
    
    var twitterAccount = ACAccount()
    private let mainQueue = dispatch_get_main_queue()


    var profileImage = UIImage()
    var screenName = ""
    var text = ""
    var idStr: String? = nil
    var favorited:Bool = false


    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var nameView: UITextView!
    @IBOutlet weak var tweetTextView: UITextView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        profileImageView.image = profileImage
        nameView.text = screenName
        tweetTextView.text = text
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        appDelegate.navigationController = navigationController!

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        if let vc = segue.destinationViewController as? TweetSheetViewController {
            vc.id = idStr
            vc.text = "@\(screenName) "
            vc.twitterAccount = self.twitterAccount
        }
    }
    
    @IBAction func retweet() {
        retweetCreate()
    }
    
    
    @IBAction func favorites() {
        if favorited {
            favoriteDestroy()
        } else {
            favoriteCreate()
        }
        favorited = !favorited
    }
    
    func retweetCreate() {
        //**
        //** リツイート手順
        //** 1. リクエスト用のパラメタを設定し、それを使ってリクエストオブジェクトを初期化
        //** 2. リクエストハンドラを作成
        //** 3. リクエストにアカウント情報をセット
        //** 4. リクエストハンドラを使ってリクエスト実行
        //**
        
        //** リクエスト生成
        let request = generateRequest()
        
        //** リクエストハンドラ作成
        let handler = generateRequestHandler()
        
        //** アカウント情報セット
        request.account = twitterAccount
        
        //** インジケータ開始
        startProcessing()
        
        //** リクエスト実行
        request.performRequestWithHandler(handler)
    }
    
    func favoriteCreate(){
        //**　リクエスト生成
        let favorites = favoriteRequest()
        
        //**　リクエストハンドラ作成
        let handler = generateRequestHandler()
        
        //** アカウント情報セット
        favorites.account = twitterAccount
        
        //** インジケータ開始
        startProcessing()
        
        //** リクエスト実行
        favorites.performRequestWithHandler(handler)
    }
    
    func favoriteDestroy()  {
        //**　リクエスト生成
        let favorites = favoriteDestroyRequest()
        
        //**　リクエストハンドラ作成
        let handler = generateRequestHandler()
        
        //** アカウント情報セット
        favorites.account = twitterAccount
        
        //** インジケータ開始
        startProcessing()
        
        //** リクエスト実行
        favorites.performRequestWithHandler(handler)
    }
    
    func tweetDestroy() {
        //**　リクエスト生成
        let tweetD = tweetDestroyRequest()
        //**　リクエストハンドラ作成
        let handler = generateRequestHandler()
        //** アカウント情報セット
        tweetD.account = twitterAccount
        //** インジケータ開始
        startProcessing()
        
        //** リクエスト実行
        tweetD.performRequestWithHandler(handler)
    }
    
    //**
    //** リクエスト生成メソッド
    //**
    private func generateRequest() -> SLRequest {
        // リクエストに必要なパラメタを用意
        let url = NSURL(string: "https://api.twitter.com/1.1/statuses/retweet/\(idStr!).json")
        
        // リクエスト初期化
        let request = SLRequest(forServiceType: SLServiceTypeTwitter,
                                requestMethod: SLRequestMethod.POST,
                                URL: url,
                                parameters: [:]) // 今回はURLにidStrを含めるのでparametersは不要
        
        return request
    }
    
    func favoriteRequest() -> SLRequest {
        let url = NSURL(string: "https://api.twitter.com/1.1/favorites/create.json")
        let request = SLRequest(forServiceType: SLServiceTypeTwitter,
                                requestMethod: SLRequestMethod.POST,
                                URL: url,
                                parameters: ["id":idStr!])
        return request
    }

    func favoriteDestroyRequest() -> SLRequest {
        let url = NSURL(string: "https://api.twitter.com/1.1/favorites/destroy.json")
        let request = SLRequest(forServiceType: SLServiceTypeTwitter,
                                requestMethod: SLRequestMethod.POST,
                                URL: url,
                                parameters: ["id":idStr!])
        return request
    }
    
    func tweetDestroyRequest() -> SLRequest {
    let url = NSURL(string:  "https://api.twitter.com/1.1/statuses/destroy/\(idStr!).json")
    let request = SLRequest(forServiceType: SLServiceTypeTwitter,
                            requestMethod: SLRequestMethod.POST,
                            URL: url,
                            parameters: [:])
        return request
    }

    
    //**
    //** リクエストハンドラ作成メソッド
    //**
    private func generateRequestHandler() -> SLRequestHandler {
        // リクエストハンドラ作成
        let handler: SLRequestHandler = { postResponseData, urlResponse, error in
            
            // リクエスト送信エラー発生時
            if let requestError = error {
                print("Request Error: An error occurred while requesting: \(requestError)")
                // インジケータ停止
                self.stopProcessing()
                return
            }
            
            // httpエラー発生時（ステータスコードが200番台以外ならエラー）
            if urlResponse.statusCode < 200 || urlResponse.statusCode >= 300 {
                print("HTTP Error: The response status code is \(urlResponse.statusCode)")
                // インジケータ停止
                self.stopProcessing()
                return
            }
            
            // JSONシリアライズ
            let objectFromJSON: AnyObject
            do {
                objectFromJSON = try NSJSONSerialization.JSONObjectWithData(
                    postResponseData,
                    options: NSJSONReadingOptions.MutableContainers)
                
                // JSONシリアライズエラー発生時
            } catch (let jsonError) {
                print("JSON Error: \(jsonError)")
                // インジケータ停止
                self.stopProcessing()
                return
            }
            
            // リツイート成功
            print("SUCCESS! Created Retweet with ID: \(objectFromJSON["id_str"] as! String)")
            // インジケータ停止
            self.stopProcessing()
        }
        return handler
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
        dispatch_async(mainQueue, {
            UIApplication.sharedApplication().networkActivityIndicatorVisible = false
        })

    }
}
