//
//  ViewController.swift
//  TwitterClient02
//
//  Created by guest on 2016/04/18.
//  Copyright © 2016年 JEC. All rights reserved.
//

import UIKit
import Social
import Accounts


class ViewController: UIViewController {
    private var twitterAccounts = [ACAccount]()
    private var twitterAccount = ACAccount()
    private var customTweetButton = UIButton()
    private var customTweetSheetButton = UIButton()
    private var timeLineButton = UIButton()
    
    @IBOutlet weak var accountLabel: UILabel!
    

    //**
    //** アカウントタイプを指定してアカウント（複数）を取得するメソッド
    //**
    func setAccountsByDevice(accountType: ACAccountType) {
        
        let accountStore = ACAccountStore()
        accountStore.requestAccessToAccountsWithType(accountType, options: nil) { granted, error in
            
            // アカウント取得に失敗したとき
            if let accountError = error {
                print("Account Error: %@", accountError.localizedDescription)
                dispatch_async(dispatch_get_main_queue(), {
                    self.accountLabel.text = "アカウント認証エラー"
                    // アカウントを取得できない場合はカスタムツイートボタンを使用不可にする
                    self.customTweetButton.enabled = false
                    self.customTweetSheetButton.enabled = false
                    self.timeLineButton.enabled = false

                })
                return
            }
            
            // アカウント情報へのアクセス権限がない時
            if !granted {
                print("Account Error: Cannot access to account data.")
                dispatch_async(dispatch_get_main_queue(), {
                    self.accountLabel.text = "アカウント認証エラー"
                    // アカウントを取得できない場合はカスタムツイートボタンを使用不可にする
                    self.customTweetButton.enabled = false
                    self.customTweetSheetButton.enabled = false
                    self.timeLineButton.enabled = false
                })
                return
            }
            
            // アカウント情報の取得に成功
            self.twitterAccounts = accountStore.accountsWithAccountType(accountType) as! [ACAccount]
            
            // Twitterアカウントが0件の時
            if (self.twitterAccounts.count <= 0){
                dispatch_async(dispatch_get_main_queue(), {
                    self.accountLabel.text = "アカウントなし"
                // アカウントを取得できない場合はカスタムツイートボタンを使用不可にする
                    self.customTweetButton.enabled = false
                    self.customTweetSheetButton.enabled = false
                    self.timeLineButton.enabled = false
                })
                // 1件以上ある時は先頭のアカウントを設定
            } else {
                self.twitterAccount = self.twitterAccounts[0]
                dispatch_async(dispatch_get_main_queue(), {
                    self.accountLabel.text = self.twitterAccount.username
                })
            }
        }
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "TweetSegue" {
            let tweetSheetVC = segue.destinationViewController as! TweetSheetViewController
            tweetSheetVC.twitterAccount = twitterAccount // 次のVCへTwitterアカウントを引き渡す
        } else if let timeLineVC = segue.destinationViewController as? BaseTableViewController{
            timeLineVC.twitterAccount = twitterAccount
        }

    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        // アカウントタイプをTwitterに設定
        let twitterAccountType = ACAccountStore().accountTypeWithAccountTypeIdentifier(ACAccountTypeIdentifierTwitter)
        
        // アカウントタイプを指定してTwitterアカウント（0件～複数件）を取得
        setAccountsByDevice(twitterAccountType)

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func setAccount() {
        let alertController = UIAlertController(
            title: "アカウント一覧",
            message: "選択してください",
            preferredStyle: .ActionSheet)
        
        //iPad用に位置を指定する
        alertController.popoverPresentationController?.sourceView = view
        alertController.popoverPresentationController?.sourceRect = CGRect(x: (view.frame.width/2), y: view.frame.height, width: 0, height: 0)
        //alertController.popoverPresentationController?.permittedArrowDirections = UIPopoverArrowDirection.Up

        
        for account in twitterAccounts {
            let otherAction = UIAlertAction(title: account.username, style: .Default) { action in
                self.twitterAccount = account
                self.accountLabel.text = account.username
                print("Account set \(account.username)")
            }
            alertController.addAction(otherAction)
        }
        
        let cancelAction = UIAlertAction(title: "キャンセル", style: .Cancel) { action in
            print("Cancel setting")
        }
        alertController.addAction(cancelAction)
        
        presentViewController(alertController, animated: true, completion: nil)
    }
    
    @IBAction func customTweet() {
        // リクエストに必要なパラメタを用意
        let tweetString = "SLRequest post test1."
        let url = NSURL(string: "https://api.twitter.com/1.1/statuses/update.json") // 画像なし
        // let url = NSURL(string: "https://api.twitter.com/1.1/statuses/update_with_media.json") // 画像付き
        let params = ["status" : tweetString]
        let request = SLRequest(forServiceType: SLServiceTypeTwitter,
            requestMethod: SLRequestMethod.POST,
            URL: url,
            parameters: params)
        
        // 画像を付加する場合
        //        let image = UIImage(named: "xcodeIcon.png")
        //        let imageData = UIImagePNGRepresentation(image!) // PNG画像の場合
        //        // let imageData = UIImageJPEGRepresentation(image!, 1.0) // JPEG画像の場合
        //        request.addMultipartData(imageData,
        //            withName: "media[]",
        //            type: "multipart/form-data",
        //            filename: nil)
        
        
        // リクエストハンドラ作成
        let handler: SLRequestHandler = { postResponseData, urlResponse, error in
            
            // リクエスト送信エラー発生時
            if let requestError = error {
                print("Request Error: An error occurred while requesting: \(requestError)")
                // インジケータ停止
                self.stopProcessing()
                return
            }
            
            // httpエラー発生時
            if urlResponse.statusCode < 200 || urlResponse.statusCode >= 300 {
                print("HTTP Error: The response status code is \(urlResponse.statusCode)")
                //** インジケータ停止
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
                //** インジケータ停止
                self.stopProcessing()
                return
            }
            
            // Tweet成功
            print("SUCCESS! Created Tweet with ID: %@", objectFromJSON["id_str"] as! String)
            // インジケータ停止
            self.stopProcessing()
        }
        
        //** アカウント情報セット
        request.account = twitterAccount
        
        //** インジケータ開始
        startProcessing()
        
        //** リクエスト実行
        request.performRequestWithHandler(handler)
    }
    
    //**
    //** インジケータ開始メソッド
    //**
    func startProcessing() {
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
    }
    
    //**
    //** インジケータ停止メソッド
    //**
    func stopProcessing() {
        dispatch_async(dispatch_get_main_queue(), {
            UIApplication.sharedApplication().networkActivityIndicatorVisible = false
        })
    }
    
    @IBAction func getTimeLine() {
        //**
        //** ユーザタイムライン取得手順
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
    //**
    //** リクエスト生成メソッド
    //**
    func generateRequest() -> SLRequest {
        // リクエストに必要なパラメタを用意
        let url = NSURL(string: "https://api.twitter.com/1.1/statuses/user_timeline.json")
        let params = ["screen_name" : twitterAccount.username,
            "include_rts" : "0",
            "trim_user" : "1",
            "count" : "1"]
        
        // リクエスト初期化
        let request = SLRequest(forServiceType: SLServiceTypeTwitter,
            requestMethod: SLRequestMethod.GET,
            URL: url,
            parameters: params)
        return request
    }

    //**
    //** リクエストハンドラ作成メソッド
    //**
    func generateRequestHandler() -> SLRequestHandler {
        // リクエストハンドラ作成
        let handler: SLRequestHandler = { getResponseData, urlResponse, error in
            
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
                    getResponseData,
                    options: NSJSONReadingOptions.AllowFragments)
                
                // JSONシリアライズエラー発生時
            } catch (let jsonError) {
                print("JSON Error: \(jsonError)")
                // インジケータ停止
                self.stopProcessing()
                return
            }
            
            // TimeLine出力
            print("TimeLine Response: \(objectFromJSON)")
            // インジケータ停止
            self.stopProcessing()
        }
        return handler
    }

}

