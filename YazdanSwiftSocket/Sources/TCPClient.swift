//  Copyright (c) <2017>, http://yazdan.xyz
//  All rights reserved.
//
//  Redistribution and use in source and binary forms, with or without
//  modification, are permitted provided that the following conditions are met:
//  1. Redistributions of source code must retain the above copyright
//  notice, this list of conditions and the following disclaimer.
//  2. Redistributions in binary form must reproduce the above copyright
//  notice, this list of conditions and the following disclaimer in the
//  documentation and/or other materials provided with the distribution.
//  3. All advertising materials mentioning features or use of this software
//  must display the following acknowledgement:
//  This product includes software developed by http://yazdan.xyz.
//  4. Neither the name of the http://yazdan.xyz nor the
//  names of its contributors may be used to endorse or promote products
//  derived from this software without specific prior written permission.
//
//  THIS SOFTWARE IS PROVIDED BY http://yazdan.xyz ''AS IS'' AND ANY
//  EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
//  WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
//  DISCLAIMED. IN NO EVENT SHALL http://yazdan.xyz BE LIABLE FOR ANY
//  DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
//  (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
//  LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
//  ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
//  (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
//  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//

import Foundation

@_silgen_name("ytcpsocket_connect") private func c_ytcpsocket_connect(_ host:UnsafePointer<Byte>,port:Int32,timeout:Int32) -> Int32
@_silgen_name("ytcpsocket_close") private func c_ytcpsocket_close(_ fd:Int32) -> Int32
@_silgen_name("ytcpsocket_send") private func c_ytcpsocket_send(_ fd:Int32,buff:UnsafePointer<Byte>,len:Int32) -> Int32
@_silgen_name("ytcpsocket_pull") private func c_ytcpsocket_pull(_ fd:Int32,buff:UnsafePointer<Byte>,len:Int32,timeout:Int32) -> Int32
@_silgen_name("ytcpsocket_listen") private func c_ytcpsocket_listen(_ address:UnsafePointer<Int8>,port:Int32)->Int32
@_silgen_name("ytcpsocket_accept") private func c_ytcpsocket_accept(_ onsocketfd:Int32,ip:UnsafePointer<Int8>,port:UnsafePointer<Int32>) -> Int32



public protocol TCPClientDelegate {
    func onMessage(message: String)
}

open class TCPClient: Socket {
    
    public var delegate: TCPClientDelegate? {didSet{self.onMessage(delegate!.onMessage)}}
    
    public var onClose: (() -> Void)?
  
    /*
     * connect to server
     * return success or fail with message
     */
    open func connect(timeout: Double) -> Result {
        let rs: Int32 = c_ytcpsocket_connect(self.address, port: Int32(self.port), timeout: Int32(timeout * 1000000))
        if rs > 0 {
            self.fd = rs
            return .success
        } else {
            switch rs {
            case -1:
                return .failure(SocketError.queryFailed)
            case -2:
                return .failure(SocketError.connectionClosed)
            case -3:
                return .failure(SocketError.connectionTimeout)
            default:
                return .failure(SocketError.unknownError)
            }
        }
    }
  
    /*
    * close socket
    * return success or fail with message
    */
    open func close() {
        guard let fd = self.fd else { return }

        _ = c_ytcpsocket_close(fd)
        self.fd = nil
    }
    
    /*
    * send data
    * return success or fail with message
    */
    open func send(data: [Byte]) -> Result {
        guard let fd = self.fd else { return .failure(SocketError.connectionClosed) }
        
        let sendsize: Int32 = c_ytcpsocket_send(fd, buff: data, len: Int32(data.count))
        if Int(sendsize) == data.count {
           return .success
        } else {
            return .failure(SocketError.unknownError)
        }
    }
    
    /*
    * send string
    * return success or fail with message
    */
    open func send(string: String) -> Result {
        guard let fd = self.fd else { return .failure(SocketError.connectionClosed) }
      
        let sendsize = c_ytcpsocket_send(fd, buff: string, len: Int32(strlen(string)))
        if sendsize == Int32(strlen(string)) {
            return .success
        } else {
            return .failure(SocketError.unknownError)
        }
    }
    
    open func write(_ string: String) -> Result {
        return send(string: "\(string)\n")
    }
    
    /*
    *
    * send nsdata
    */
    open func send(data: Data) -> Result {
        guard let fd = self.fd else { return .failure(SocketError.connectionClosed) }
      
        var buff = [Byte](repeating: 0x0,count: data.count)
        (data as NSData).getBytes(&buff, length: data.count)
        let sendsize = c_ytcpsocket_send(fd, buff: buff, len: Int32(data.count))
        if sendsize == Int32(data.count) {
            return .success
        } else {
            return .failure(SocketError.unknownError)
        }
    }
    
    /*
    * read data with expect length
    * return success or fail with message
    */
    open func read(_ expectlen:Int, timeout:Double = 0.1) -> [Byte]? {
        guard let fd:Int32 = self.fd else { return nil }
      
        var buff = [Byte](repeating: 0x0,count: expectlen)
        let readLen = c_ytcpsocket_pull(fd, buff: &buff, len: Int32(expectlen), timeout: Int32(timeout * 1000000))
        if readLen <= 0 { return nil }
        let rs = buff[0...Int(readLen-1)]
        let data: [Byte] = Array(rs)
      
        return data
    }
    
    open func read(until: String, timeout: Double = 5000.0) -> String? {
        let first = Date().timeIntervalSince1970
        var data: [Byte] = []
        var string: String?
        var _string: String = ""
        while !_string.contains(until) {
            if let first = self.read(1, timeout: 0.1)?.first {
                data.append(first)
            }
            if let str = String(bytes: data, encoding: .utf8) {
                if str != "" {
                    string = str
                }
                _string = str
            }
            if Date().timeIntervalSince1970 - first > timeout {
                return string
            }
        }
        return string
    }
    
    open func read(until: String, timeout: Double = 1.0, _ action: @escaping (String) -> Void, _ failed: (() -> Void)? = nil) {
        DispatchQueue.global(qos: .background).async {
            if let str = self.read(until: until, timeout: timeout) {
                DispatchQueue.main.async {action(str)}
            } else {
                DispatchQueue.main.async {failed?()}
            }
        }
    }
    
    var registered = false
    
    private func readString() {
        registered = true
        while registered {
            var data: [Byte] = []
            var hasData = true
            while hasData {
                if let first = self.read(1, timeout: 0.01)?.first {
                    data.append(first)
                } else {
                    hasData = false
                    usleep(1000)
                }
            }
            if let str = String(bytes: data, encoding: .utf8), str != "" {
                DispatchQueue.main.async {
                    self._onMsg(str)
                }
            }
        }
    }
    
    
    private var _until: [String: (String) -> Void] = [:]
    public func until(until u: String, timeout: Double = 1.0, _ action: @escaping (String) -> Void, _ failed: (() -> Void)? = nil) {
        _until[u] = action
        q.asyncAfter(deadline: .now() + timeout) {
            if self._until[u] != nil {
                self._until.removeValue(forKey: u)
                failed?()
            }
        }
    }
    
    private func _onMsg(_ msg: String) {
        if msg != "" {
            onMsg?(msg)
            for (u, item) in _until {
                _until[u] = nil
                if (msg + "\n").contains(u) {item(msg)}
            }
        }
    }
    private var onMsg: ((String) -> Void)?
    private var q = DispatchQueue.init(label: "YazdanSwiftSocketBackground", qos: DispatchQoS.init(qosClass: DispatchQoS.QoSClass.background, relativePriority: 0), attributes: DispatchQueue.Attributes.concurrent, autoreleaseFrequency: DispatchQueue.AutoreleaseFrequency.inherit, target: nil)
    
    public func onMessage(_ action: @escaping ((String) -> Void)) {
        self.onMsg = action
        if registered {
            registered = false
            q.asyncAfter(deadline: DispatchTime.now() + 1) {
                self.readString()
            }
        } else {
            q.async {
                self.readString()
            }
        }
    }

}

open class TCPServer: Socket {

    open func listen() -> Result {
        let fd = c_ytcpsocket_listen(self.address, port: Int32(self.port))
        if fd > 0 {
            self.fd = fd
            return .success
        } else {
            return .failure(SocketError.unknownError)
        }
    }
    
    open func accept() -> TCPClient? {
        guard let serferfd = self.fd else { return nil }
        
        var buff: [Int8] = [Int8](repeating: 0x0,count: 16)
        var port: Int32 = 0
        let clientfd: Int32 = c_ytcpsocket_accept(serferfd, ip: &buff, port: &port)
        
        guard clientfd >= 0 else { return nil }
        guard let address = String(cString: buff, encoding: String.Encoding.utf8) else { return nil }
        
        let client = TCPClient(address: address, port: port)
        client.fd = clientfd
            
        return client
    }
    
    open func close() {
        guard let fd: Int32=self.fd else { return }
      
        _ = c_ytcpsocket_close(fd)
        self.fd = nil
    }
}
