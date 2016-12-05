# iOSPingTester
iOS ping(ICMP)网络测试demo，用于在iOS中比较多个地址的丢包率、延迟。

### 测试方法

```swif
let addresses = ["blog.6ag.cn", "www.baidu.com", "www.qq.com"]

JFPingManager.getFastestAddress(addressList: addresses) { (address) in
    guard let address = address else {
        print("所有地址都没有ping通")
        return
    }
    
    print("address = \(address)")
}
```

### 测试结果

![image](https://github.com/6ag/iOSPingTester/blob/master/1.png)

