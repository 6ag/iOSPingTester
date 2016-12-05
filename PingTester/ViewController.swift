//
//  ViewController.swift
//  PingTester
//
//  Created by zhoujianfeng on 2016/12/5.
//  Copyright © 2016年 zhoujianfeng. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
    }

    @IBAction func didTapped(_ sender: UIButton) {
        
        let addresses = ["blog.6ag.cn", "www.baidu.com", "www.qq.com"]

        JFPingManager.getFastestAddress(addressList: addresses) { (address) in
            guard let address = address else {
                print("所有地址都没有ping通")
                return
            }
            
            print("address = \(address)")
        }
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

