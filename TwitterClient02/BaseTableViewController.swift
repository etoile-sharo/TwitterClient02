//
//  BaseTableViewController.swift
//  TwitterClient02
//
//  Created by guest on 2016/05/27.
//  Copyright © 2016年 JEC. All rights reserved.
//

import UIKit
import Social
import Accounts

class BaseTableViewController: UITableViewController,UIGestureRecognizerDelegate{
    var twitterAccount = ACAccount() // 選択されたTwitterタイプのアカウント
    var screenName = ""
    var id:String? = nil
    var timeLineArray: [AnyObject] = [] // タイムライン行の配列
    var statusArray: [Status] = [] //パースの配列
    var httpMessage = "" // 接続待ち時及び接続エラー時のメッセージ
    private let mainQueue = dispatch_get_main_queue() // メインキュー
    private let imageQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0) // グローバルキュー
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        //テーブルビューのセルの高さを自動計算する
        tableView.estimatedRowHeight = 60
        tableView.rowHeight = UITableViewAutomaticDimension
        
        //リフレッシュコントロールの初期化
        refreshControl = UIRefreshControl()
        refreshControl?.addTarget(self, action: #selector(BaseTableViewController.refreshTableView), forControlEvents: UIControlEvents.ValueChanged)
        
        //テーブルビューの中身が空の場合でもリフレッシュコントロールを使えるようにする
        tableView.alwaysBounceVertical = true
        
        //タイムラインリクエスト
        requestTimeLine()
        
        let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(BaseTableViewController.cellLongPressed))
        
        // `UIGestureRecognizerDelegate`を設定するのをお忘れなく
        longPressRecognizer.delegate = self
        
        // tableViewにrecognizerを設定
        tableView.addGestureRecognizer(longPressRecognizer)

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }
    
    
    @objc func cellLongPressed(sender: UILongPressGestureRecognizer){
        // 押された位置でcellのPathを取得
        let point = sender.locationInView(tableView)
        let indexPath = tableView.indexPathForRowAtPoint(point)
        if indexPath == nil {
            // 長押し位置に対する行数が取得できなければ何もしない
        } else if sender.state == UIGestureRecognizerState.Began {
            // 長押しされた場合の処理
            let selectItems = statusArray[indexPath?.row ?? 0]
            let alertController:UIAlertController = UIAlertController(title: nil, message: "選択してください", preferredStyle: .ActionSheet)
            if twitterAccount.username == selectItems.screenName {
            let firstAction = UIAlertAction(title: "ツイートを削除", style: .Default) { action in
                let req = self.tweetDestroyRequest(selectItems.idStr)
                let handler: SLRequestHandler = { getResponseData, urlResponse, error in
                    
                    // リクエスト送信エラー発生時
                    if let requestError = error {
                        print("Request Error: An error occurred while requesting: \(requestError)")
                        self.httpMessage = "HTTPエラー発生"
                        // インジケータ停止
                        self.stopProcessing()
                        return
                    }
                    
                    // httpエラー発生時（ステータスコードが200番台以外ならエラー）
                    if urlResponse.statusCode < 200 || urlResponse.statusCode >= 300 {
                        print("HTTP Error: The response status code is \(urlResponse.statusCode)")
                        self.httpMessage = "HTTPエラー発生"
                        // インジケータ停止
                        self.stopProcessing()
                        return
                    }
                    
                    self.stopProcessing()
                    
                    dispatch_async(self.mainQueue){
                        self.statusArray.removeAtIndex(indexPath!.row)
                        self.tableView.reloadData()
                    }
                }
                req.account = self.twitterAccount
                self.startProcessing()
                req.performRequestWithHandler(handler)
            }
            alertController.addAction (firstAction)
            }
            let cancelAction = UIAlertAction (title: "キャンセル", style: .Cancel) {
                action in
            }
            alertController.addAction (cancelAction)
            
            //iPad用に位置を指定する
            alertController.popoverPresentationController?.sourceView = tableView
            alertController.popoverPresentationController?.sourceRect = CGRect(x: (tableView.frame.width/2), y: tableView.frame.height, width: 0, height: 0)
//            alertController.popoverPresentationController?.permittedArrowDirections = UIPopoverArrowDirection.Up
            self.presentViewController(alertController, animated: true, completion: nil)
        }
    }

    
    @objc private func refreshTableView() {
        //リフレッシュ開始　インジケーター開始
        refreshControl?.beginRefreshing()
        
        // dispatch_async()のメインキュー処理ブロック内に記述する必要がある。
        requestTimeLine()
        
        refreshControl?.endRefreshing()
    }


    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    func requestTimeLine(){
    }
    
    func tweetDestroyRequest(idStr:String) -> SLRequest {
        let url = NSURL(string:  "https://api.twitter.com/1.1/statuses/destroy/\(idStr).json")
        let request = SLRequest(forServiceType: SLServiceTypeTwitter,
                                requestMethod: SLRequestMethod.POST,
                                URL: url,
                                parameters: [:])
        return request
    }
    
    func generateRequest() -> SLRequest {
        return SLRequest()
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
                self.httpMessage = "HTTPエラー発生"
                // インジケータ停止
                self.stopProcessing()
                return
            }
            
            // httpエラー発生時（ステータスコードが200番台以外ならエラー）
            if urlResponse.statusCode < 200 || urlResponse.statusCode >= 300 {
                print("HTTP Error: The response status code is \(urlResponse.statusCode)")
                self.httpMessage = "HTTPエラー発生"
                // インジケータ停止
                self.stopProcessing()
                return
            }
            
            // JSONシリアライズ
            do {
                self.timeLineArray = try NSJSONSerialization.JSONObjectWithData(
                    getResponseData,
                    options: NSJSONReadingOptions.AllowFragments) as? [AnyObject] ?? []
                
                // JSONシリアライズエラー発生時
            } catch (let jsonError) {
                print("JSON Error: \(jsonError)")
                // インジケータ停止
                self.stopProcessing()
                return
            }
            
            // TimeLine出力
            print("TimeLine Response: \(self.timeLineArray)")
            
            // TimeLineの配列のパース
            self.statusArray = self.parseJSON(self.timeLineArray)
            
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
    private func stopProcessing() {
        dispatch_async(self.mainQueue, {
            UIApplication.sharedApplication().networkActivityIndicatorVisible = false
            //テーブルビューの再描画
            
            //リフレッシュ終了　インジケータ停止
            //通常以下の処理はこのメソッド内で良いが、今回の更新処理は非同期なので
            self.tableView.reloadData()
            self.refreshControl?.endRefreshing()
        })
    }
    
    //**
    //** タイムラインJSONパースメソッド
    //** （タイムライン配列をパースして必要なデータのみ返す）
    //** （パースに失敗したらfatal error）
    //**
    private func parseJSON(json: [AnyObject]) -> [Status] {
        return json.map{ result in
            guard let text = result["text"] as? String else {
                fatalError("Parse error!") }
            guard let user = result ["user"] as? NSDictionary else {
                fatalError("Parse error!") }
            guard let screenName = user["screen_name"] as? String else {
                fatalError("Parse error!") }
            guard let profileImageUrlHttps =
                user["profile_image_url_https"] as? String else {
                    fatalError("Parse error!") }
            guard let favorited =
                result["favorited"] as? Bool else {
                    fatalError("Parse error!") }
            guard let idStr = result["id_str"] as? String else { fatalError("Prase error!") }
            return Status(
                text: text,
                screenName: screenName,
                profileImageUrlHttps: profileImageUrlHttps,
                idStr: idStr,
                favorited: favorited
            )
        }
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        if timeLineArray.count == 0 {
            return 20; // タイムラインがサーバから送られてくるまでは1行メッセージを表示（Loading... or Error）
        } else {
            return timeLineArray.count; // タイムラインが得られたら件数分セルを確保
        }
        
    }
    
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath) as! TimeLineCell
        
        // Configure the cell…
        
        var celltext = "";
        var celluserName = "";
        var cellImageViewImage = UIImage()
        
        if timeLineArray.count == 0 { // タイムラインが返ってこない時
            if httpMessage != "" { // HTTPエラーがあれば
                celltext = httpMessage
            } else { // まだ通信中なら
                celltext = "Loading..."
            }
        } else { //タイムタインが返っていれば
            // パース済みのデータをセットする
            let status = statusArray[indexPath.row]
            celltext = status.text // つぶやきは「text」
            celluserName = status.screenName // ユーザ名は「screenName」
            
            //ユーザ画像の取得処理(グローバルキューで並列処理）
            //　ユーザ画像の取得処理（グローバルキューで並列処理）
            dispatch_async(self.imageQueue, {
                // パース済みデータから画像URLを生成
                guard let imageUrl = NSURL(string: status.profileImageUrlHttps) else {
                    fatalError("URL Error!")
                }
                // 画像URLを利用してアイコン画像取得
                do {
                    let imageData = try NSData(
                        contentsOfURL: imageUrl,
                        options:NSDataReadingOptions.DataReadingMappedIfSafe)
                    cellImageViewImage = UIImage(data: imageData)!
                } catch (let imageError) {
                    print("Image loading Error: (\(imageError))")
                }
                // 画像が取得できたらセルにセットしてセルの再描画
                dispatch_async(self.mainQueue, {
                    cell.profileImageView!.image = cellImageViewImage
                    cell.setNeedsLayout() // セルのみ再描画
                })
            })
            
        }
        cell.tweetTextLabel?.text = celltext
        cell.nameLabel?.text = celluserName
        cell.profileImageView?.image = UIImage(named: "blank.png") //デフォルトは空白画像
        //UITableViewCellのstyleを「subtitle」にした場合
        //textLabelとdetailLabelが上位に並ぶ
        //            cell.textLabel?.font = UIFont.systemFontOfSize(14)
        //            cell.detailTextLabel?.font = UIFont.systemFontOfSize(12)
        //            cell.textLabel?.numberOfLines = 0 // UILabelの行数を文字数によって変える
        return cell
    }


    /*
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("reuseIdentifier", forIndexPath: indexPath)

        // Configure the cell...

        return cell
    }
    */

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

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
