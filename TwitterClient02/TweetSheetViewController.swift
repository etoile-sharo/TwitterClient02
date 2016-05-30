//
//  TweetSheetViewController.swift
//  TwitterClient02
//
//  Created by guest on 2016/04/22.
//  Copyright © 2016年 JEC. All rights reserved.
//

import UIKit
import Accounts
import Social

class TweetSheetViewController: UIViewController,UINavigationControllerDelegate, UIImagePickerControllerDelegate, UIPopoverControllerDelegate {

    var twitterAccount = ACAccount()
    private let mainQueue = dispatch_get_main_queue()
    var id:String? = nil
    var text:String? = ""
    var idStr:String? = nil
    
    @IBOutlet weak var tweetTextView: UITextView!
    @IBOutlet weak var openGallery: UIImageView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tweetTextView.text = text
        self.automaticallyAdjustsScrollViewInsets = false
        
         openGallery.contentMode = .ScaleAspectFit
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

    @IBAction func tweetWithCustomSheet() {
        //**
        //** カスタムツイート手順
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
        
        //** モーダルビューのdismiss
        self.dismissViewControllerAnimated(true, completion: {
            print("Tweet Sheet has been dismissed.")
        })
    }
    
    
    
    //**
    //** リクエスト生成メソッド
    //**
    func generateRequest() -> SLRequest {
        // リクエストに必要なパラメタを用意
        let withMedia = openGallery.image != nil ? "_with_media" : ""
        let url = NSURL(string: "https://api.twitter.com/1.1/statuses/update\(withMedia).json")
        let params:[NSObject:AnyObject]
        if let id = self.id {
            params = ["status":tweetTextView.text,"in_reply_to_status_id":id]
        } else {
            params = ["status":tweetTextView.text]
        }
        
        
        // リクエスト初期化
        let request = SLRequest(forServiceType: SLServiceTypeTwitter,
            requestMethod: SLRequestMethod.POST,
            URL: url,
            parameters: params)
        if let image = openGallery.image {
            let imageData = UIImageJPEGRepresentation(image, 0.85)
            request.addMultipartData(imageData, withName: "media[]" , type: "multipart/form-data", filename: nil)
        }
        return request
    }
    
    func favoriteRequest() -> SLRequest { //お気に入り
        let url = NSURL(string: "https://api.twitter.com/1.1/favorites/create.json")
        let params : [NSObject:AnyObject]
        if let idStr = self.idStr {
            params = ["status":tweetTextView.text,"in_reply_to_status_id":idStr]
        } else {
            params = ["status":tweetTextView.text]
        }
        
        let request = SLRequest(forServiceType: SLServiceTypeTwitter,
                               requestMethod: SLRequestMethod.POST,
                               URL: url,
                               parameters: params)
        return request
    }

    func favoriteDestroyRequest() -> SLRequest { //お気に入り解除
        let url = NSURL(string: "https://api.twitter.com/1.1/favorites/destroy.json")
        let params : [NSObject : AnyObject]
        if let idStr = self.idStr {
            params = ["status":tweetTextView.text,"in_reply_to_status_id":idStr]
        } else {
            params = ["status":tweetTextView.text]

        }
        let request = SLRequest(forServiceType: SLServiceTypeTwitter,
                                requestMethod: SLRequestMethod.POST,
                                URL: url,
                                parameters: params)
        return request
    }
    
    func tweetDestroyRequest() -> SLRequest {
        let url = NSURL(string:  "https://api.twitter.com/1.1/statuses/destroy/:id.json")
        let params : [NSObject :AnyObject]
        if let id = self.id {
            params = ["status":tweetTextView.text,"in_reply_to_status_id":id]
        } else {
            params = ["status":tweetTextView.text]
        }
        let request = SLRequest(forServiceType: SLServiceTypeTwitter,
                                requestMethod: SLRequestMethod.POST,
                                URL: url,
                                parameters: params)
        return request
    }
    
    
    @IBAction func returnView() {
        self.dismissViewControllerAnimated(true, completion: {
            print("Tweet Sheet has been dismissed.")
        })
    }

    //**
    //** リクエストハンドラ作成メソッド
    //**
    func generateRequestHandler() -> SLRequestHandler {
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
            
            // Tweet成功
            print("SUCCESS! Created Tweet with ID: \(objectFromJSON["id_str"] as! String)")
            // インジケータ停止
            self.stopProcessing()
        }
        return handler
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
        dispatch_async(mainQueue, {
            UIApplication.sharedApplication().networkActivityIndicatorVisible = false
        })
    }
    
    /**
     ライブラリから写真を選択する
     */
    func pickImageFromLibrary() {
        
        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.PhotoLibrary) {    //追記
            
            //写真ライブラリ(カメラロール)表示用のViewControllerを宣言しているという理解
            let controller = UIImagePickerController()
            controller.delegate = self
            
            //新しく宣言したViewControllerでカメラとカメラロールのどちらを表示するかを指定
            //カメラロールの例
            //.Cameraを指定した場合はカメラを呼び出し(シミュレーター不可)
            controller.sourceType = UIImagePickerControllerSourceType.PhotoLibrary
            
            //新たに追加したカメラロール表示ViewControllerをpresentViewControllerにする
            self.presentViewController(controller, animated: true, completion: nil)
        }
    }
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo: [String: AnyObject]) {
        
        if didFinishPickingMediaWithInfo[UIImagePickerControllerOriginalImage] != nil {
            
            //didFinishPickingMediaWithInfo通して渡された情報(選択された画像情報が入っている？)をUIImageにCastする
            //そしてそれを宣言済みのimageViewへ放り込む
            openGallery.image = didFinishPickingMediaWithInfo[UIImagePickerControllerOriginalImage] as? UIImage
            
            
        }
        
        //写真選択後にカメラロール表示ViewControllerを引っ込める動作
        picker.dismissViewControllerAnimated(true, completion: nil)
    }

    // フォトライブラリーを開く
    @IBAction func connectionAlbum(sender : AnyObject) {
         pickImageFromLibrary()
    }
}
