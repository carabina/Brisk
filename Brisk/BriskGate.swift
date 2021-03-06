//
//  BriskGate.swift
//  Brisk
//
//  Copyright (c) 2016-Present Jason Fieldman - https://github.com/jmfieldman/Brisk
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

import Foundation


// BriskGate is an intelligent semaphore mechanism that can
// perform waits from the main thread without freezing the
// application (though it does so inefficiently).

internal class BriskGate {
    
    var isMain:     Bool
    var group:      dispatch_group_t?   = nil
    var finished:   Bool                = false
    
    init() {
        isMain = NSThread.currentThread().isMainThread
        if !isMain {
            group = dispatch_group_create()
            dispatch_group_enter(group!)
        }
    }
    
    func signal() {
        finished = true
        if !isMain {
            dispatch_group_leave(group!)
        }
    }
    
    func wait() {
        if isMain {
            while !finished {
                NSRunLoop.currentRunLoop().runMode(NSDefaultRunLoopMode, beforeDate: NSDate(timeIntervalSinceNow: 0.1))
            }
        } else {
            dispatch_group_wait(group!, DISPATCH_TIME_FOREVER)
        }
    }
    
}