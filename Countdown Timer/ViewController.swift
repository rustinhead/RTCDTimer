//
//  ViewController.swift
//
//  Created by 傅祚鹏 on 2018/4/18.
//  Copyright © 2018年 Rusted. All rights reserved.
//

import UIKit
import CoreLocation

class ViewController: UIViewController {
    
    @IBOutlet weak var label: UILabel!
    
    var countdown:RTCDTimer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
    }
    @IBAction func butt(_ sender: Any) {
        
        let vc = TestViewController.init(nibName: "TestViewController", bundle: nil)
        self.present(vc, animated: true, completion: nil)

    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

