//
//  RecurrencePickerDelegate.swift
//  RecurrencePicker
//
//  Created by Xin Hong on 16/4/7.
//  Copyright © 2016年 Teambition. All rights reserved.
//

import Foundation
import RRuleSwift

public protocol RecurrencePickerDelegate {
    func recurrencePicker(picker: RecurrencePicker, didPickRecurrence recurrenceRule: RecurrenceRule?)
}

public extension RecurrencePickerDelegate {
    func recurrencePicker(picker: RecurrencePicker, didPickRecurrence recurrenceRule: RecurrenceRule?) {

    }
}