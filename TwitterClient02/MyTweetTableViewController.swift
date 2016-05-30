//
//  MyTweetTableViewController.swift
//  TwitterClient02
//
//  Created by guest on 2016/05/27.
//  Copyright © 2016年 JEC. All rights reserved.
//

import UIKit
import Accounts
import Social

class MyTweetTableViewController: BaseTableViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
        override func requestTimeLine() {
            //**
            //** ホームタイムライン取得手順
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
        override func generateRequest() -> SLRequest {
            // リクエストに必要なパラメタを用意
            let url = NSURL(string: "https://api.twitter.com/1.1/statuses/user_timeline.json" )
            
            let params = ["screen_name" : screenName]
            // リクエスト初期化
            let request = SLRequest(forServiceType: SLServiceTypeTwitter,
                                    requestMethod: SLRequestMethod.GET,
                                    URL: url,
                                    parameters: params)
            return request
        }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        switch segue.destinationViewController { // パターンマッチングでセグエ処理を分ける
        case let detailVC as DetailViewController:
            let indexPath = tableView.indexPathForSelectedRow // 選択されたセルの行番号を得る
            let status = statusArray[indexPath!.row] // パース済みデータから該当セル分を得る
            
            // セルの内容を次のVCへ引き渡す
            detailVC.text = status.text
            detailVC.screenName = status.screenName
            detailVC.idStr = status.idStr
            detailVC.twitterAccount = twitterAccount
            detailVC.favorited = status.favorited
            
            
            // ユーザアイコン画像はStatus構造体に含まれないので、該当セルの画像を使う
            let cell = tableView.cellForRowAtIndexPath(indexPath!) as! TimeLineCell
            detailVC.profileImage = cell.profileImageView.image!
            
        default:
            print("Segue has no parameters.")
        }
    }
}
