//
//  TestViewController.swift
//
//  Created by 傅祚鹏 on 2018/4/23.
//  Copyright © 2018年 Rusted. All rights reserved.
//

import UIKit

class TestViewController: UIViewController,RTCDTimerDelegate {
    func oneSecondCallback(cdtimer: RTCDTimer, leftSeconds: Int) {
        label.text = "距离程序崩溃还有\(leftSeconds)秒"
    }
    
    func countdownDidComplete(cdtimer: RTCDTimer) {
        print("********** countdown complete **delegate***")
//        fatalError("Oops !!")
    }
    

//    lazy var countdown:RTCDTimer = {
//        let cd = RTCDTimer.init(identifier: "ffff", owner: self, delegate: self)
//        return cd
//    }()
    
    var countdown:RTCDTimer?

    func fetchCountdown() -> RTCDTimer! {
        if countdown == nil {
            countdown = RTCDTimer.init(identifier: "Fffff", owner: self, delegate: self)
        }
        return countdown!
    }
    
    @IBOutlet weak var label: UILabel!
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func butt(_ sender: Any) {
        fetchCountdown().startNewCountdown(seconds: 60, owner: nil, handlerPerSecond: nil, completion: nil)
    }
    
    @IBAction func continuecd(_ sender: Any) {
        if fetchCountdown().fetchCountdown(owner: nil, handlerPerSecond: nil, completion: nil) {
            print("******** countdown running ********")
        }else{
            print("******** no countdown ********")
        }
    }
    @IBAction func appendcd(_ sender: Any) {
        fetchCountdown().appendCountdown(seconds: 10, owner: self, handlerPerSecond: { (t) in
            print("closure - \(t) s")
        }) {
            print("closure - finished")
        }
    }
    @IBAction func cancelcd(_ sender: Any) {
        fetchCountdown().cancel()
    }
    @IBAction func back(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    
    deinit {
//        countdown?.invalidate()
        debugPrint("************* TestViewController Deinit *****************")
    }

}
