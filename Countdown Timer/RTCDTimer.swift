//
//  RTCDTimer.swift
//
//  Created by 傅祚鹏 on 2018/4/18.
//  Copyright © 2018年 Rusted. All rights reserved.
//

import UIKit

struct RTCountdown {
    var id:String?                 //计时器id
    var fireDate:Date?             //倒计时启动日期
    var totalTimeInterval:Double?  //总倒计时时长
    var currentTimeInterval:Double?//当前已进行时长
    
    init(data:Array<Any>) {
        self.id = data[0] as? String
        self.fireDate = data[1] as? Date
        self.totalTimeInterval = data[2] as? Double
        self.currentTimeInterval = data[3] as? Double
    }
}

protocol RTCDTimerDelegate:NSObjectProtocol {
    func oneSecondCallback(cdtimer:RTCDTimer, leftSeconds:Int)
    func countdownDidComplete(cdtimer:RTCDTimer)
}

class RTCDTimer {
    
    private var identifier:String?             //计时器ID
    
    private let identiferPrefix = "RTCDTimer-" //本地化储存key前缀
    
    private var countdown:RTCountdown?         //倒计时数据
    
    private var timer:Timer?                   //计时器
    
    private weak var owner:NSObject?           //计时器持有者
    
    private var oneSecHandler:((Int)->Void)?   //倒计时每秒执行闭包，传参剩余秒数
    
    private var completionHandler:(()->Void)?  //倒计时完成后回调闭包
    
    private weak var delegate:RTCDTimerDelegate?
    
    
    /// 初始化计时器，采用代理方式回调；使用此方法初始化后，即使设置闭包函数也不生效
    init(identifier:String, owner:NSObject!, delegate:RTCDTimerDelegate!) {
        self.identifier = identifier
        self.owner = owner
        self.delegate = delegate
        addObserver()
    }
    
    
    /// 初始化计时器，采用闭包函数方式回调；使用此方法初始化后，即使设置代理也不会调用代理方法
    init(identifier:String, owner:NSObject!, handlerPerSecond:((Int)->Void)?, completion:(()->Void)?){
        self.identifier = identifier
        self.owner = owner
        self.oneSecHandler = handlerPerSecond
        self.completionHandler = completion
        addObserver()
    }
    
    
    /// 开启新的倒计时，原有的倒计时将被清除
    ///
    /// - Parameters:
    ///   - seconds: 倒计时长度
    ///   - owner: 计时器持有者，传nil则使用初始化时传入的对象
    ///   - handlerPerSecond: 每秒回调,传nil则执行初始化时传入的回调函数
    ///   - completion: 倒计时完毕回调，传nil则执行初始化时传入的回调函数
    func startNewCountdown(seconds:Double, owner:NSObject?, handlerPerSecond:((Int)->Void)?, completion:(()->Void)?) {
        removeLocalData(for: identifier!)
        invalidate()
        if delegate == nil {reset(owner: owner, handlerPerSecond: handlerPerSecond, completion: completion)}
        let dataArr = [self.identifier!, Date.init(), seconds, 0.0] as [Any]
        countdown = RTCountdown.init(data: dataArr)
        timer = newTimer()
    }
    
    
    /// 继续已有的倒计时,重置回调函数,若调用时该id的倒计时已经完成或数据不存在，则返回false，未完成则返回true，返回false时，handlerPerSecond和completion均不会执行
    ///
    /// - Parameters:
    ///   - owner: 计时器持有者，传nil则使用初始化时传入的对象
    ///   - handlerPerSecond: 每秒回调，传nil则执行初始化时传入的回调函数
    ///   - completion: 倒计时完毕回调，传nil则执行初始化时传入的回调函数
    func fetchCountdown(owner:NSObject?, handlerPerSecond:((Int)->Void)?, completion:(()->Void)?) -> Bool{
        if timer != nil{//已有计时器在运行
            if delegate == nil {reset(owner: owner, handlerPerSecond: handlerPerSecond, completion: completion)}
            return true
        }else{//没有计时器在运行
            if let cd = getLocalData() {//本地存在数据,继续倒计时
                countdown = cd
                if delegate == nil {reset(owner: owner, handlerPerSecond: handlerPerSecond, completion: completion)}
                timer = newTimer()
                return true
            }else{//本地无数据
                return false
            }
        }
    }
    
    
    /// 原有倒计时基础上延长计时，重置回调函数，若原有倒计时已完成，则开启新的倒计时
    ///
    /// - Parameters:
    ///   - seconds: 延长部分时长
    ///   - owner: 计时器持有者，传nil则使用初始化时传入的对象
    ///   - handlerPerSecond: 每秒回调，传nil则执行初始化时传入的回调函数
    ///   - completion: 倒计时完毕回调，传nil则执行初始化时传入的回调函数
    func appendCountdown(seconds:Double, owner:NSObject?, handlerPerSecond:((Int)->Void)?, completion:(()->Void)?){
        if fetchCountdown(owner: owner, handlerPerSecond: handlerPerSecond, completion: completion) {
            let pre = countdown!.totalTimeInterval!
            countdown?.totalTimeInterval = pre + seconds
        }else{
            startNewCountdown(seconds: seconds, owner: owner, handlerPerSecond: handlerPerSecond, completion: completion)
        }
    }
    
    
//    /// 在正在运行的倒计时基础上延长计时，若原有倒计时已完成，则开启新的倒计时，执行之前传入的回调函数
//    ///
//    /// - Parameter second: 延长部分时长
//    func appendCountdown(seconds:Double){
//        if timer != nil && countdown != nil {//倒计时正在运行
//            let pre = countdown!.totalTimeInterval!
//            countdown?.totalTimeInterval = pre + seconds
//        }else{
//            let dataArr = [self.identifier!, Date.init(), seconds, 0.0] as [Any]
//            countdown = RTCountdown.init(data: dataArr)
//            timer = newTimer()
//        }
//    }

    /// 取消倒计时，直接执行完成回调,清除本地数据
    func cancel(){
        if completionHandler != nil {completionHandler!()}
        delegate?.countdownDidComplete(cdtimer: self)
        if oneSecHandler != nil {oneSecHandler!(0)}
        delegate?.oneSecondCallback(cdtimer: self, leftSeconds: 0)
        timer?.invalidate()
        timer = nil
        removeLocalData(for: self.identifier!)
    }
    
    private func reset(owner:NSObject?, handlerPerSecond:((Int)->Void)?, completion:(()->Void)?){
        if owner != nil {self.owner = owner}
        if handlerPerSecond != nil {oneSecHandler = handlerPerSecond}
        if completion != nil {completionHandler = completion}
    }
    
    private func addObserver(){
        NotificationCenter.default.addObserver(self, selector: #selector(appWillTerminate), name: NSNotification.Name.UIApplicationWillTerminate, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(appDidBecomeActive), name: NSNotification.Name.UIApplicationDidBecomeActive, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(appWillResignActive), name: NSNotification.Name.UIApplicationWillResignActive, object: nil)
    }
    //使该计时器失效
    private func invalidate(){
        timer?.invalidate()
        timer = nil
        countdown = nil
    }
    
    
    func newTimer() -> Timer{
        if oneSecHandler != nil {oneSecHandler!(Int(self.countdown!.totalTimeInterval! - self.countdown!.currentTimeInterval!))}
        delegate?.oneSecondCallback(cdtimer: self, leftSeconds: Int(self.countdown!.totalTimeInterval! - self.countdown!.currentTimeInterval!))
        let previous = countdown!.currentTimeInterval!
        countdown?.currentTimeInterval = previous + 1.0
        let t = Timer.init(timeInterval: 1, target: self, selector: #selector(oneCount), userInfo: nil, repeats: true)
        RunLoop.current.add(t, forMode: RunLoopMode.commonModes)
//        return Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(oneCount), userInfo: nil, repeats: true)
        return t
    }
    
    /// 获取已本地化的倒计时数据
    private func getLocalData() ->RTCountdown?{
        let fixedId = identiferPrefix + self.identifier!
        if let obj = UserDefaults.standard.object(forKey: fixedId){//本地有数据
            let data = obj as! Dictionary<String,Any>
            let fireDate = data["fireDate"] as? Date
            let total = data["totalTimeInterval"] as? Double
            if Date.init().timeIntervalSince(fireDate!) > total! {//本地数据已过期
                removeLocalData(for: fixedId)
                return nil
            }else{
                let id = data["id"] as? String
                let fireDate = data["fireDate"] as? Date
                let totalTimeInterval = data["totalTimeInterval"] as? Double
                let currentTimeInterval = Date.init().timeIntervalSince(fireDate!)
                let dataArr = [id!, fireDate!, totalTimeInterval!, currentTimeInterval] as [Any]
                let countdown = RTCountdown.init(data: dataArr)
                removeLocalData(for: fixedId)
                return countdown
            }
        }else{//本地无数据
            return nil
        }
    }
    
    
    /// 删除本地化数据
    ///
    /// - Parameter identifier: 计时器ID
    func removeLocalData(for identifier:String){
        let fixedId = identiferPrefix + identifier
        UserDefaults.standard.removeObject(forKey: fixedId)
    }
    
    @objc private func oneCount(){
        if owner == nil {
            timer?.invalidate()
            timer = nil
            return
        }
        let leftTime = countdown!.totalTimeInterval! - countdown!.currentTimeInterval!
        
        if leftTime >= 0 {
            if oneSecHandler != nil {self.oneSecHandler!(Int(leftTime))}
            delegate?.oneSecondCallback(cdtimer: self, leftSeconds: Int(leftTime))
            let previous = countdown!.currentTimeInterval!
            countdown?.currentTimeInterval = previous + 1.0
        }
        if leftTime < 1 {
            countdown = nil
            timer?.invalidate()
            timer = nil
            if completionHandler != nil {completionHandler!()}
            delegate?.countdownDidComplete(cdtimer: self)
        }
    }
    
    /// 校正当前已进行时长
    func fixCurrentTimeInterval(){
        let current = Date.init().timeIntervalSince(countdown!.fireDate!)
        if current >= countdown!.totalTimeInterval! {//倒计时已完成
            if completionHandler != nil {completionHandler!()}
            delegate?.countdownDidComplete(cdtimer: self)
            if oneSecHandler != nil {oneSecHandler!(0)}
            delegate?.oneSecondCallback(cdtimer: self, leftSeconds: 0)
            timer?.invalidate()
            timer = nil
            removeLocalData(for: self.identifier!)
        }else{
            countdown?.currentTimeInterval = current
        }
    }
    
    /// 保存未完成的倒计时数据至本地
    private func saveUnfinishedCountdown(){
        if countdown != nil {
            let data:Dictionary<String,Any> = ["id":countdown!.id!,"fireDate":countdown!.fireDate!,"totalTimeInterval":countdown!.totalTimeInterval!]
            UserDefaults.standard.set(data, forKey: identiferPrefix + countdown!.id!)
        }
    }
    
    @objc private func appDidBecomeActive(){
        fixCurrentTimeInterval()
    }
    
    @objc private func appWillTerminate(){
        saveUnfinishedCountdown()
    }
    
    @objc private func appWillResignActive(){
        saveUnfinishedCountdown()
    }
    
    deinit {
        debugPrint("************* RTCDTimer Deinit *****************")
        saveUnfinishedCountdown()
        NotificationCenter.default.removeObserver(self)
    }
}
