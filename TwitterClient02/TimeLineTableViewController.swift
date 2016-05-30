//
//  TimeLineTableViewController.swift
//  TwitterClient02
//
//  Created by guest on 2016/04/25.
//  Copyright © 2016年 JEC. All rights reserved.
//

import UIKit
import Accounts
import Social

class TimeLineTableViewController: BaseTableViewController{
    override func viewDidLoad() {
        super.viewDidLoad()        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }
        
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle,indexPath: NSIndexPath) {
        if editingStyle == UITableViewCellEditingStyle.Delete {
            
        }
    }
    
    override func generateRequest() -> SLRequest {
        // リクエストに必要なパラメタを用意
        let url = NSURL(string: "https://api.twitter.com/1.1/statuses/home_timeline.json")
        let params = ["include_rts" : "0",
                      "trim_user" : "0",
                      "count" : "50"]
        
        // リクエスト初期化
        let request = SLRequest(forServiceType: SLServiceTypeTwitter,
                                requestMethod: SLRequestMethod.GET,
                                URL: url,
                                parameters: params)
        return request
    }
    
    //**
    //** タイムラインリクエストメソッド
    //**
    override func requestTimeLine(){
        //**
        //** ホームタイムライン取得手順
        //** 1. リクエスト用のパラメタを設定し、それを使ってリクエストオブジェクトを初期化
        //** 2. リクエストハンドラを作成
        //** 3. リクエストにアカウント情報をセット
        //** 4. リクエストハンドラを使ってリクエスト実行
        //**
        
        //** リクエスト生成
        
        let request = self.generateRequest()
        
        //** リクエストハンドラ作成
        let handler = self.generateRequestHandler()
        
        //** アカウント情報セット
        request.account = twitterAccount
        
        //** インジケータ開始
        startProcessing()
        
        //** リクエスト実行
        request.performRequestWithHandler(handler)
 
 
    }    
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
//    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
//        return 140.0;
//    }

    /*
    // Override to support conditional editing of the table view.
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            // Delete the row from the data source
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        } else if editingStyle == .Insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        
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
