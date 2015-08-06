//
//  BookListViewController.swift
//  TdTalk2
//
//  Created by Fujiwara on 2015/07/05.
//  Copyright (c) 2015年 FSAP. All rights reserved.
//

import UIKit

class BookListViewController : UIViewController, UITableViewDelegate, UITableViewDataSource, BookServiceDelegate {
    
    struct Const {
        static let kBookListViewLineHeight :CGFloat = 64.0
    }

    @IBOutlet weak var bookListTableView: UITableView!
    
    var bookList :[BookEntity] = []
    var manager: DataManager = DataManager.sharedInstance
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        LogM("viewDidLoad")
        // Do any additional setup after loading the view, typically from a nib.
        self.navigationItem.title = NSLocalizedString("page_title_book_list", comment: "")
        self.navigationItem.rightBarButtonItem = self.editButtonItem()
        self.bookListTableView.delegate = self
        
        var bookService = TTBookService.sharedInstance
        bookService.delegate = self
        
        self.bookList = bookService.getBookList()
//        if self.bookList.count == 0 {
//            self.createBooks()
//            self.bookList = TTBookService.sharedInstance.getBookList()
//        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // 編集モードへの切り替え
    override func setEditing(editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        self.bookListTableView?.setEditing(editing, animated: animated)
    }
    
    // test
    private func createBooks()->Void {
        
        for (var i=0; i<5; i++) {
            var book: BookEntity = self.manager.getEntity(DataManager.Const.kBookEntityName) as! BookEntity
            book.title = NSString(format: "title_%d", i) as String
            book.sort_num = i
            manager.save()
        }
    }
    
    // 並び順をリフレッシュする
    private func refreshSort()->Void {
        for (index, book: BookEntity) in enumerate(self.bookList) {
            book.sort_num = index
            self.manager.save()
        }
        self.bookListTableView.reloadData()
    }
    
    
    //
    // MARK: UITableViewDelegate
    //
    
    // セクションの数
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        LogM("sections:[1]")
        return 1
    }
    
    // セクションあたり行数
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return bookList.count
    }
    
    // 行の高さ
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return Const.kBookListViewLineHeight
    }
    
    // セルの設定
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell: UITableViewCell = UITableViewCell(style: UITableViewCellStyle.Default, reuseIdentifier: "Cell")
        let book = bookList[indexPath.row]
        cell.textLabel?.text = book.title

        return cell
    }
    
    // セルが選択された
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
    
    // 編集可否の設定
    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        Log(NSString(format: "section:%d row:%d", indexPath.section, indexPath.row))
        return true
    }
    
    // 編集時のスタイル
    func tableView(tableView: UITableView, editingStyleForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCellEditingStyle {
        Log(NSString(format: "section:%d row:%d", indexPath.section, indexPath.row))
        if (self.editing) {
            return .Delete
        }
        return .None
    }
    
    // スワイプ時のアクション(iOS8用)
//    func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [AnyObject]? {
//        let delAction = UITableViewRowAction(style: .Default, title: NSLocalizedString("row_action_delete", comment: "")) { (action, indexPath) -> Void in
//            TTAlertController(nibName: nil, bundle: nil).show(
//                self.view,
//                title:NSLocalizedString("dialog_title_error", comment: ""),
//                message:"削除")
//        }
//        delAction.backgroundColor = UIColor.redColor()
//        
//        return [delAction]
//    }
    
    // 編集の確定タイミングで呼ばれる
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        switch editingStyle {
        case .Delete:
            // 確認を取る
            TTAlertController(nibName: nil, bundle: nil).show(self,
                title: NSLocalizedString("dialog_title_notice", comment: ""),
                message: NSLocalizedString("dialog_msg_delete", comment: ""),
                actionOk: { () -> Void in
                    let book: BookEntity = self.bookList[indexPath.row]
                    var result: TTErrorCode = TTBookService.sharedInstance.deleteBook(book)
                    if result == TTErrorCode.Normal {
                        self.bookList.removeAtIndex(indexPath.row)
                        self.bookListTableView?.deleteRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Left)
                        self.refreshSort()
                    } else {
                        TTAlertController(nibName: nil, bundle: nil).show(self,
                            title: NSLocalizedString("dialog_title_error", comment: ""),
                            message: TTError.getErrorMessage(result), actionOk: { () -> Void in})
                    }
            }, actionCancel:nil)
            return
        default:
            return
        }
    }
    
    // 移動可否の設定
    func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        Log(NSString(format: "section:%d row:%d", indexPath.section, indexPath.row))
        return true
    }
    
    // 移動の確定タイミングで呼ばれる
    func tableView(tableView: UITableView, moveRowAtIndexPath sourceIndexPath: NSIndexPath, toIndexPath destinationIndexPath: NSIndexPath) {

        var sourceBook: BookEntity = self.bookList[sourceIndexPath.row]
        self.bookList.removeAtIndex(sourceIndexPath.row)
        self.bookList.insert(sourceBook, atIndex: destinationIndexPath.row)
        self.refreshSort()
    }
    
    
    //
    // MARK: BookServiceDelegate
    //
    
    func importCompleted() {
        LogM("importCompleted")
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            self.bookList = TTBookService.sharedInstance.getBookList()
            self.bookListTableView.reloadData()
        })
    }
}