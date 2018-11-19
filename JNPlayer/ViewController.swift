//
//  ViewController.swift
//  JNPlayer
//
//  Created by 贾楠 on 2018/11/19.
//  Copyright © 2018 贾楠. All rights reserved.
//

import UIKit

class ViewController: UIViewController,UITableViewDelegate,UITableViewDataSource {
    
    let dataArray : [String] = ["http://u2-test.img.ugirls.tv/ugcv/cma_4329841_8nk63aox.mp4","http://u2-test.img.ugirls.tv/ugcv/cma_4328935_d8ip715h.mp4","http://u2-test.img.ugirls.tv/ugcv/cma_4329802_ls70mu4g.mp4","http://u2-test.img.ugirls.tv/ugcv/cma_4329841_8nk63aox.mp4","http://u2-test.img.ugirls.tv/ugcv/cma_4328935_d8ip715h.mp4","http://u2-test.img.ugirls.tv/ugcv/cma_4329802_ls70mu4g.mp4"]
    
    var isPlayingCell : UITableViewCell!     //正在播放视图

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        self.view.addSubview(self.tableView)
        self.tableView.register(UITableViewCell.classForCoder(), forCellReuseIdentifier: "cell")
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        self.firstPlayVideo()
    }

    lazy var tableView: UITableView! = {
        var tableView = UITableView(frame: CGRect(x: 0, y: 0, width: MY_WIDTH, height: MY_HEIGHT), style: UITableViewStyle.grouped)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.classForCoder(), forCellReuseIdentifier: "Cell")
        return tableView
    }()
    
    //MARK: UITableViewDelegate
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataArray.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return MY_WIDTH
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath as IndexPath)
        cell.backgroundColor = UIColor.black
        return cell
    }
    
    //MARK: 加载视频滚动方法
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        self.handleScrollPlaying()
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        self.handleScrollPlaying()
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        
        let array : [UITableViewCell] = (tableView?.visibleCells)!
        if (self.isPlayingCell != nil){
            if !array.contains(self.isPlayingCell){
                JNPlayer.shared.removePlayer()
            }
        }
    }

    //播放第一条视频
    func firstPlayVideo(){
        let array : [UITableViewCell] = (tableView?.visibleCells)!
        if let firstCell : UITableViewCell = array.first{
            self.isPlayingCell = array.first
            self.initPlayer(cell: firstCell)
        }
    }
    
    //初始化播放器，添加到cell
    func initPlayer(cell : UITableViewCell) {
        
        let indexPath = self.tableView?.indexPath(for: cell)
        let urlPath = dataArray[(indexPath?.row)!]
        let arr = urlPath.components(separatedBy: "/")
        let documentPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first
        let savePath = String(format:"%@/%@",documentPath ?? "" , arr.last ?? "")
        JNPlayer.shared.initPlayer(superView: cell.contentView, urlPath: urlPath, savePath: savePath)
    }
    
    //根据居中位置找到需要播放的cell
    func handleScrollPlaying() {
        
        let array : [UITableViewCell] = (tableView?.visibleCells)!
        var gap : CGFloat = CGFloat(MAXFLOAT)
        var finnalCell : UITableViewCell?
        
        for cell in array {
            let center = cell.superview?.convert(cell.center, to: nil)
            let delta = fabs((center?.y)! - UIScreen.main.bounds.size.height * 0.5)
            if delta < gap{
                gap = delta
                finnalCell = cell
            }
        }
        
        if finnalCell != nil && self.isPlayingCell != finnalCell{
            JNPlayer.shared.removePlayer()
            self.isPlayingCell = finnalCell
            self.initPlayer(cell: finnalCell!)
        }
    }
    
}

