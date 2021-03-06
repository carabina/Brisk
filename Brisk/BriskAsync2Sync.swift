//
//  BriskAsync2Sync.swift
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

// let .. = <<-{ func(i, handler: $0) }              call func on current queue
// let .. = <<~{ func(i, handler: $0) }              call func on bg queue
// let .. = <<+{ func(i, handler: $0) }              call func on main queue
// let .. = <<~myQueue ~~~ { func(i, handler: $0) }   call func on specified queue

prefix operator <<- {}
prefix operator <<~ {}
prefix operator <<+ {}
infix  operator ~~~ { precedence 95 }


/// Returns the queue this prefix is applied to.  This is used to prettify the
/// syntax:
///
/// - e.g.: let x = <<~myQueue ~~~ { func(i, handler: $0) }
@inline(__always) public prefix func <<~(q: dispatch_queue_t) -> dispatch_queue_t {
    return q
}

/// Executes the attached operation synchronously on the current queue
/// and waits for it to complete.  Returns the result of the callback handler that
/// $0 was attached to.
///
/// - e.g.: ```let x = <<-{ func(i, callback: $0)``` }
public prefix func <<-<O>(@noescape operation: (callbackHandler: (param: O) -> ()) -> ()) -> O {
    
    // Our gating mechanism
    let gate = BriskGate()
    
    // This value will eventually hold the response from the async function
    var handledResponse: O?
    
    let theHandler: (p: O) -> () = { responseFromCallback in
        handledResponse = responseFromCallback
        gate.signal()
    }
    
    operation(callbackHandler: theHandler)
    gate.wait()
    
    // It's ok to use ! -- theoretically we are garanteed that handledResponse
    // has been set by this point (inside theHandler)
    return handledResponse!
}

/// Using a generic handler for the non-noescape versions
@inline(__always) private func processAsync2Sync<O>(operation: (callbackHandler: (param: O) -> ()) -> (),
                                                        queue: dispatch_queue_t) -> O {
    
    // Our gating mechanism
    let gate = BriskGate()
    
    // This value will eventually hold the response from the async function
    var handledResponse: O?
    
    let theHandler: (p: O) -> () = { responseFromCallback in
        handledResponse = responseFromCallback
        gate.signal()
    }
    
    dispatch_async(queue) {
        operation(callbackHandler: theHandler)
    }
    
    gate.wait()
    
    // It's ok to use ! -- theoretically we are garanteed that handledResponse
    // has been set by this point (inside theHandler)
    return handledResponse!
}


/// Executes the attached operation on the general concurrent background queue
/// and waits for it to complete.  Returns the result of the callback handler that
/// $0 was attached to.
///
/// - e.g.: ```let x = <<~{ func(i, callback: $0)``` }
public prefix func <<~<O>(operation: (callbackHandler: (param: O) -> ()) -> ()) -> O {
    return processAsync2Sync(operation, queue: backgroundQueue)
}


/// Executes the attached operation on the main queue
/// and waits for it to complete.  Returns the result of the callback handler that
/// $0 was attached to.
///
/// - e.g.: ```let x = <<+{ func(i, callback: $0)``` }
public prefix func <<+<O>(operation: (callbackHandler: (param: O) -> ()) -> ()) -> O {
    return processAsync2Sync(operation, queue: mainQueue)
}


/// Executes the attached operation on the supplied queue from the left side
/// and waits for it to complete.  Returns the result of the callback handler that
/// $0 was attached to.
///
/// - e.g.: ```let x = <<~myQueue ~~~ { func(i, callback: $0)``` }
public func ~~~<O>(lhs: dispatch_queue_t, rhs: (callbackHandler: (param: O) -> ()) -> ()) -> O {
    return processAsync2Sync(rhs, queue: lhs)
}

