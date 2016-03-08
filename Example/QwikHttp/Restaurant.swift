//
//  Restaurant.swift
//  QwikHttp
//
//  Created by Logan Sease on 2/26/16.
//  Copyright © 2016 CocoaPods. All rights reserved.
//

import Foundation
import QwikJson

@objc class Restaurant : QwikJson{
    var image_url : String?
    var name : String?
    var createdAt : DBTimeStamp?
}