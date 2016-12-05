//
//  JFPingServices.swift
//  WindSpeedVPN
//
//  Created by zhoujianfeng on 2016/12/3.
//  Copyright © 2016年 zhoujianfeng. All rights reserved.
//

import UIKit

/// ping状态
///
/// - didStart: 开始ping
/// - didFailToSendPacket: 发包失败
/// - didReceivePacket: 接收到正常包
/// - didReceiveUnexpectedPacket: 接收到异常包
/// - didTimeout: 超时
/// - didError: 错误
/// - didFinished: 完成
enum JFPingStatus {
    case didStart
    case didFailToSendPacket
    case didReceivePacket
    case didReceiveUnexpectedPacket
    case didTimeout
    case didError
    case didFinished
}

class JFPingItem: NSObject {
    
    /// 主机名
    var hostName: String?
    
    /// 单次耗时（单位：毫秒）
    var timeMilliseconds: Double?
    
    /// ping状态
    var status: JFPingStatus?
    
}

class JFPingServices: NSObject {

    fileprivate var hostName: String?
    fileprivate var pinger: SimplePing?
    fileprivate var sendTimer: Timer?
    fileprivate var startDate: Date?
    fileprivate var runloop: RunLoop?
    fileprivate var pingCallback: ((_ pingItem: JFPingItem) -> ())?
    fileprivate var count: Int = 0
    
    init(hostName: String, count: Int, pingCallback: @escaping (_ pingItem: JFPingItem) -> ()) {
        super.init()
        self.hostName = hostName
        self.count = count
        self.pingCallback = pingCallback
        let pinger = SimplePing(hostName: hostName)
        self.pinger = pinger
        pinger.addressStyle = .any
        pinger.delegate = self
        pinger.start()
    }
    
    /// 开始ping服务
    ///
    /// - Parameters:
    ///   - hostName: 主机名
    ///   - count: ping次数
    ///   - pingCallback: 回调
    class func start(hostName: String, count: Int, pingCallback: @escaping (_ pingItem: JFPingItem) -> ()) -> JFPingServices {
        return JFPingServices(hostName: hostName, count: count, pingCallback: pingCallback)
    }
    
    /// 停止ping服务
    @objc fileprivate func stop() {
        print(self.hostName! + " stop")
        clean(status: .didFinished)
    }
    
    /// ping超时
    @objc fileprivate func timeout() {
        print(hostName! + " timeout")
        clean(status: .didTimeout)
    }
    
    /// ping失败
    @objc fileprivate func fail() {
        print(hostName! + " fail")
        clean(status: .didError)
    }
    
    /// 清理数据
    fileprivate func clean(status: JFPingStatus) {
        
        let pingItem = JFPingItem()
        pingItem.hostName = self.hostName
        pingItem.status = status
        pingCallback?(pingItem)
        
        pinger?.stop()
        pinger = nil
        
        sendTimer?.invalidate()
        sendTimer = nil
        
        runloop?.cancelPerform(#selector(timeout), target: self, argument: nil)
        runloop = nil
        
        hostName = nil
        startDate = nil
        pingCallback = nil
        
    }
    
    /// 发送ping指令
    @objc fileprivate func sendPing() {
        if count < 1 {
            stop()
            return
        }
        count -= 1
        startDate = Date()
        pinger!.send(with: nil)
        runloop?.perform(#selector(timeout), with: self, afterDelay: 1.0)
    }
    
}

// MARK: - SimplePingDelegate
extension JFPingServices: SimplePingDelegate {
    
    /// 开始ping
    func simplePing(_ pinger: SimplePing, didStartWithAddress address: Data) {
        print("start ping \(self.hostName!)")
        
        self.sendPing()
        assert(self.sendTimer == nil)
        self.sendTimer = Timer.scheduledTimer(timeInterval: 0.4, target: self, selector: #selector(sendPing), userInfo: nil, repeats: true)
        
        let pingItem = JFPingItem()
        pingItem.hostName = self.hostName
        pingItem.status = .didStart
        pingCallback?(pingItem)
    }
    
    /// ping失败
    func simplePing(_ pinger: SimplePing, didFailWithError error: Error) {
        runloop?.cancelPerform(#selector(timeout), target: self, argument: nil)
        print(self.hostName! + " " + error.localizedDescription)
        self.fail()
    }
    
    /// 发包成功
    func simplePing(_ pinger: SimplePing, didSendPacket packet: Data, sequenceNumber: UInt16) {
        runloop?.cancelPerform(#selector(timeout), target: self, argument: nil)
        print(self.hostName! + " #\(sequenceNumber) send packet success")
    }
    
    /// 发包失败
    func simplePing(_ pinger: SimplePing, didFailToSendPacket packet: Data, sequenceNumber: UInt16, error: Error) {
        runloop?.cancelPerform(#selector(timeout), target: self, argument: nil)
        print(self.hostName! + " #\(sequenceNumber) send failed: \(error.localizedDescription)")
        clean(status: .didFailToSendPacket)
    }
    
    /// 接收到正常包
    func simplePing(_ pinger: SimplePing, didReceivePingResponsePacket packet: Data, sequenceNumber: UInt16) {
        runloop?.cancelPerform(#selector(timeout), target: self, argument: nil)
        let timeMilliseconds = Date().timeIntervalSince(self.startDate!) * 1000
        print(self.hostName! + " #\(sequenceNumber) received, size=\(packet.count) time=\(String(format: "%.2f", timeMilliseconds)) ms")
        let pingItem = JFPingItem()
        pingItem.hostName = self.hostName
        pingItem.status = .didReceivePacket
        pingItem.timeMilliseconds = timeMilliseconds
        pingCallback?(pingItem)
    }
    
    /// 异常包 - 不处理
    func simplePing(_ pinger: SimplePing, didReceiveUnexpectedPacket packet: Data) {
        runloop?.cancelPerform(#selector(timeout), target: self, argument: nil)
    }
}

