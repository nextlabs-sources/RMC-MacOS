//
//  ExceptionTools.swift
//  skyDRM
//
//  Created by Ivan (Youmin) Zhang on 2019/1/26.
//  Copyright © 2019 nextlabs. All rights reserved.
//

import Foundation
import ExceptionHandling

func registerException() {
    registerSignalHandler()
    NSSetUncaughtExceptionHandler(UncaughtExceptionHandler)
}

func UncaughtExceptionHandler(excep: NSException) {
    print("成功了");
}

func SignalExceptionHandler(signal:Int32) -> Void
{
    print("Signal 成功了");
}

func registerSignalHandler(){
    
    //    如果在运行时遇到意外情况，Swift代码将以SIGTRAP此异常类型终止，例如：
    //    1.具有nil值的非可选类型
    //    2.一个失败的强制类型转换
    //    查看Backtraces以确定遇到意外情况的位置。附加信息也可能已被记录到设备的控制台。您应该修改崩溃位置的代码，以正常处理运行时故障。例如，使用可选绑定而不是强制解开可选的。
    
    signal(SIGABRT, SignalExceptionHandler)
    signal(SIGSEGV, SignalExceptionHandler)
    signal(SIGBUS, SignalExceptionHandler)
    signal(SIGTRAP, SignalExceptionHandler)
    signal(SIGILL, SignalExceptionHandler)
}
