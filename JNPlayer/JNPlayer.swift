//
//  USMainPlayer.swift
//  social
//
//  Created by 贾楠 on 2018/10/31.
//  Copyright © 2018 ugirls. All rights reserved.
//

import AVFoundation
import UIKit

let MY_WIDTH = UIScreen.main.bounds.width
let MY_HEIGHT = UIScreen.main.bounds.height

class JNPlayer:NSObject
{
    var view : UIView?
    var playerLayer : AVPlayerLayer!
    var playerItem : AVPlayerItem!
    var avPlayer : AVPlayer!
    var needLoad : Bool! = false
    var savePath : String!  //视频播放完后保存的本地路径
    var videoPath : String!
    var activity : UIActivityIndicatorView?
    var enterBackGround : Bool! = false
    var audioBtn : UIButton?
    class var shared:JNPlayer {
        
        struct Static {
            static let instance = JNPlayer()
        }
        
        return Static.instance
    }
    
    func initPlayer(superView : UIView , urlPath : String , savePath : String){
        
        self.removePlayer()
        
        var asset : AVAsset

        self.initView(superview : superView)
        
        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: savePath) {
            videoPath = savePath
            needLoad = false
        }else{
            videoPath = urlPath
            needLoad = true
            activity?.startAnimating()
        }
        
        self.savePath = savePath
        
        if videoPath == nil { return }
        
        if videoPath.hasPrefix("http"){
            asset = AVAsset.init(url: URL.init(string: videoPath)!)
        }else{
            asset = AVAsset.init(url: URL.init(fileURLWithPath: videoPath))
        }
        
        weak var weakself = self
        asset.loadValuesAsynchronously(forKeys: ["playable"]) {
            DispatchQueue.main.async {
                weakself?.creatPlayer(asset: asset)
            }
        }
    }
    
    func initView(superview : UIView){
        self.view = UIView.init(frame: CGRect(x: 0, y: 0, width: MY_WIDTH, height: MY_WIDTH))
        superview.addSubview(self.view!)
        
        activity = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.whiteLarge)
        let center = self.view?.center
        activity?.frame = CGRect(x: (center?.x ?? 0) - 40, y: (center?.y ?? 0) - 40, width: 80, height: 80)
        superview.addSubview(activity!)
        superview.bringSubview(toFront: activity!)
        
        audioBtn = UIButton.init(frame: CGRect(x: 0, y: 0, width: 45, height: 45))
        audioBtn?.setImage(UIImage(named: "audio_on"), for: UIControlState.normal)
        audioBtn?.addTarget(self, action: #selector(audioButtonClick(sender:)), for: .touchUpInside)
        superview.addSubview(audioBtn!)
        superview.bringSubview(toFront: audioBtn!)
        
    }
    
    @objc func audioButtonClick(sender: UIButton) {
        if sender.isSelected {
            audioBtn?.setImage(UIImage(named: "audio_off"), for: UIControlState.normal)
            self.setVolume(volume: 0)
        }else{
            audioBtn?.setImage(UIImage(named:"audio_on"), for: UIControlState.selected)
            self.setVolume(volume: 1)
        }
        sender.isSelected = !sender.isSelected
    }
    
    func creatPlayer(asset : AVAsset) {
        
        let generator = AVAssetImageGenerator.init(asset: asset)
        generator.appliesPreferredTrackTransform = true
        
        let playerItem = AVPlayerItem.init(asset: asset)
        self.playerItem = playerItem
        self.avPlayer = AVPlayer.init(playerItem: self.playerItem)
        
        self.playerLayer = AVPlayerLayer(player: self.avPlayer)
        self.playerLayer.frame = (self.view?.bounds)!
        self.playerLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        self.view?.layer.addSublayer(self.playerLayer)

        self.play()
        
        self.initNotificationAndKVO()
    }
    
    func initNotificationAndKVO() {
        if needLoad{
            // 监听缓冲进度改变
            self.playerItem.addObserver(self, forKeyPath: "loadedTimeRanges", options: NSKeyValueObservingOptions.new, context: nil)
            // 监听状态改变
            self.playerItem.addObserver(self, forKeyPath: "status", options: NSKeyValueObservingOptions.new, context: nil)
            //缓冲不足
            self.playerItem.addObserver(self, forKeyPath: "playbackBufferEmpty", options: NSKeyValueObservingOptions.new, context: nil)
            //缓冲完成
            self.playerItem.addObserver(self, forKeyPath: "playbackLikelyToKeepUp", options: NSKeyValueObservingOptions.new, context: nil)
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(playerItemDidReachEnd(notification:)), name: Notification.Name.AVPlayerItemDidPlayToEndTime, object: self.playerItem)
        NotificationCenter.default.addObserver(self, selector: #selector(onEnterForeground), name: .UIApplicationWillEnterForeground, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onEnterBackground), name: .UIApplicationDidEnterBackground, object: nil)

    }
    
    //播放结束，回到最开始位置
    @objc func playerItemDidReachEnd(notification: Notification){
        avPlayer?.seek(to: kCMTimeZero, toleranceBefore: kCMTimeZero, toleranceAfter: kCMTimeZero)
        avPlayer.play()
    }
    
    //kvo监听
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if enterBackGround == true { return }
        guard let playerItem = object as? AVPlayerItem else { return }
        if keyPath == "status"{
            // 监听状态改变
            if playerItem.status == AVPlayerItemStatus.readyToPlay{
//                let duration = playerItem.duration.value / playerItem.duration.timescale
//                print(duration)
            }else if playerItem.status == AVPlayerItemStatus.failed || playerItem.status == AVPlayerItemStatus.unknown{
                avPlayer.pause()
            }
            
        }else if keyPath == "loadedTimeRanges"{     //下载进度
            let loadedTimeRanges = playerItem.loadedTimeRanges
            let timeRange = loadedTimeRanges.first?.timeRangeValue      //缓冲区域
            let startSeconds = CMTimeGetSeconds((timeRange?.start)!)
            let durationSeconds = CMTimeGetSeconds((timeRange?.duration)!)
            let timeInterval = startSeconds + durationSeconds       //缓冲总长度
            let duration = playerItem.duration
            let totalDuration = CMTimeGetSeconds(duration)
            
            let loadTime = String(format:"%.3f",timeInterval)       //缓冲时间
            let totalTime = String(format:"%.3f",totalDuration)        //总时间
            
            if Float(loadTime) ?? 0 >= Float(totalTime) ?? 0 {     //下载完成
                
                activity?.stopAnimating()
                
                let composition = AVMutableComposition.init()
                //音频轨道
                let compositionAudioTrack = composition.addMutableTrack(withMediaType: AVMediaType.audio, preferredTrackID: CMPersistentTrackID(kCMPersistentTrackID_Invalid))
                //视频轨道
                let compositionVideoTrack = composition.addMutableTrack(withMediaType: AVMediaType.video, preferredTrackID: CMPersistentTrackID(kCMPersistentTrackID_Invalid))
                
                let sourceVideoTrack = playerItem.asset.tracks(withMediaType: AVMediaType.video).first!
                let sourceAudioTrack = playerItem.asset.tracks(withMediaType: AVMediaType.audio).first!
            
                //方向修正
                let t = sourceVideoTrack.preferredTransform
                if(t.a == 0 && t.b == 1.0 && t.c == -1.0 && t.d == 0){
                    //90
                    compositionVideoTrack?.preferredTransform = CGAffineTransform(rotationAngle: CGFloat( Double.pi / 2))
                }else if(t.a == 0 && t.b == -1.0 && t.c == 1.0 && t.d == 0){
                    //270
                    compositionVideoTrack?.preferredTransform = CGAffineTransform(rotationAngle: CGFloat( Double.pi + Double.pi / 2))
                }else if(t.a == 1.0 && t.b == 0 && t.c == 0 && t.d == 1.0){
                    //0
                }else if(t.a == -1.0 && t.b == 0 && t.c == 0 && t.d == -1.0){
                    //180
                    compositionVideoTrack?.preferredTransform = CGAffineTransform(rotationAngle: CGFloat( Double.pi))
                }
                
                do {//插入音视频轨道
                    try compositionVideoTrack?.insertTimeRange(CMTimeRangeMake(kCMTimeZero, playerItem.duration), of: sourceVideoTrack, at: kCMTimeZero)
                    try compositionAudioTrack?.insertTimeRange(CMTimeRangeMake(kCMTimeZero, playerItem.duration), of: sourceAudioTrack, at: kCMTimeZero)
                } catch(let err) {
                    print(err.localizedDescription)
                }
                
                let compatiblePresets = AVAssetExportSession.exportPresets(compatibleWith: composition)
                var preset: String = AVAssetExportPresetPassthrough
                if compatiblePresets.contains(AVAssetExportPreset640x480) { preset = AVAssetExportPreset640x480 }
                
                //压缩视频
                guard let exporter = AVAssetExportSession(asset: composition, presetName: preset),
                    exporter.supportedFileTypes.contains(AVFileType.mp4) else { return }
                //输出URL
                exporter.outputURL = URL.init(fileURLWithPath: savePath)
                //转换后的格式
                exporter.outputFileType = AVFileType.mp4
                //优化网络
                exporter.shouldOptimizeForNetworkUse = true
                weak var weakself = self
                //异步导出
                exporter.exportAsynchronously(completionHandler: {
                    //导出完成
                    if exporter.status == AVAssetExportSessionStatus.completed && (weakself?.needLoad)!{
                        print("保存成功")
                        weakself?.needLoad = false
                        weakself?.playerItem.removeObserver(weakself!, forKeyPath: "status")
                        weakself?.playerItem.removeObserver(weakself!, forKeyPath: "loadedTimeRanges")
                        weakself?.playerItem.removeObserver(weakself!, forKeyPath: "playbackBufferEmpty")
                        weakself?.playerItem.removeObserver(weakself!, forKeyPath: "playbackLikelyToKeepUp")
                    }else if (exporter.status == AVAssetExportSessionStatus.failed){
                        print(exporter.error.debugDescription as Any)
                    }
                })
            }
        }else if keyPath == "playbackBufferEmpty"{          //监听缓冲
            print("缓冲不足，暂停")
            activity?.startAnimating()
        }else if keyPath == "playbackLikelyToKeepUp"{
            print("缓冲已足够，播放")
            activity?.stopAnimating()
            if self.avPlayer == nil {return}
            avPlayer.play()
        }
    }
    
    @objc func onEnterBackground(){
        enterBackGround = true
        self.pause()
    }
    @objc func onEnterForeground(){
        enterBackGround = false
        self.play()
    }
    
    func play() {
        if self.avPlayer == nil {return}
        self.avPlayer.play()
    }
    
    func pause() {
        if self.avPlayer == nil {return}
        self.avPlayer.pause()
    }
    
    func setVolume(volume : Float) {
        self.avPlayer.volume = volume
    }
    
    func removePlayer() {

        audioBtn?.removeFromSuperview()
        self.view?.removeFromSuperview()
        
        if avPlayer != nil {
            
            if needLoad{
                //            print(avPlayer,self.playerItem)
                self.playerItem.removeObserver(self, forKeyPath: "status")
                self.playerItem.removeObserver(self, forKeyPath: "loadedTimeRanges")
                self.playerItem.removeObserver(self, forKeyPath: "playbackBufferEmpty")
                self.playerItem.removeObserver(self, forKeyPath: "playbackLikelyToKeepUp")
            }
            NotificationCenter.default.removeObserver(self)
            
            avPlayer.pause()
//            avPlayer.currentItem?.cancelPendingSeeks()
//            avPlayer.currentItem?.asset.cancelLoading()
            avPlayer.replaceCurrentItem(with: nil)
            avPlayer = nil
            playerLayer.removeFromSuperlayer()
            playerLayer = nil
            
            activity?.stopAnimating()
            activity?.removeFromSuperview()

        }
    }
}
