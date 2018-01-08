//
//  main.swift
//  Wii Fit Data
//
//  Created by Tristan Beaton on 8/01/18.
//  Copyright © 2018 Tristan Beaton. All rights reserved.
//

import Foundation

let path = "/Users/tristanbeaton/Desktop/0001000452465050/FitPlus0.dat"
let profiles = WiiFitProfile.extract(file: path)

profiles.forEach { print(); print($0) }

