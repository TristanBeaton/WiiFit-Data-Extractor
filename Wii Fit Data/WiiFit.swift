//
//  WiiFit.swift
//  Wii Fit Data
//
//  Created by Tristan Beaton on 8/01/18.
//  Copyright © 2018 Tristan Beaton. All rights reserved.
//

import Foundation

struct WiiFitProfile: CustomStringConvertible {
    // Mii Name
    var name: String
    // Height in cm
    var height: Int
    // Date of Birth
    var year: Int
    var month: Int
    var day: Int
    // Body Test Records
    var records = Array<WiiFitRecord>()
    
    init(_ name:String, _ height:Int, _ year:Int, _ month:Int, _ day:Int) {
        self.name = name
        self.height = height
        self.year = year
        self.month = month
        self.day = day
    }
    
    var description: String {
        var str = "Mii: \(name)\nHeight: \(height)cm\nDOB: \(year.formatted())-\(month.formatted())-\(day.formatted())"
        str.append("\nBody Test Records:\n\t  Date & Time          Weight  BMI   Balance")
        records.forEach { str.append(contentsOf: "\n\t- \($0)") }
        return str
    }
    
    var isEmpty:Bool {
        if name.isEmpty == true || year == 0 || month == 0 || day == 0 {
            return true
        }
        return false
    }
    
    static func extract(file:String) -> Array<WiiFitProfile> {
        // Store Profiles
        var profiles = Array<WiiFitProfile>()
        // Create an input stream to read file.
        do {
            let stream = try WiiFileStream(fileAtPath: path)
            // Set record size.
            let recordSize = 37505
            // Read Records
            while stream.hasBytesAvailable {
                // Create a profile reference
                var profile: WiiFitProfile?
                // Extract profile data
                do {
                    // Octets 1-8. Header "RPHE0000"
                    let _ = try stream.skip(8)
                    // Octets 9-30. Name of Mii
                    let name = try stream.readString(22)
                    // Octet 31. Unknown
                    try stream.skip()
                    // Octet 32. Height (cm)
                    let height = try stream.readInt8()
                    // Octets 33-36. Date of Birth
                    let (year, month, day) = try stream.readBCDDate()
                    // Octets 37-14496. Unknown
                    let _ = try stream.skip(14461)
                    // Instantiate profile
                    profile = WiiFitProfile(name, height, year, month, day)
                    // Read Records
                    while stream.bytesRead < recordSize {
                        // Create record instance
                        var record = WiiFitRecord()
                        // Octets 1-4. Date
                        record.date = try stream.readBitfieldDate()
                        // Octets 5-6. Weight
                        record.weight = Double(try stream.readUI16()) / 10
                        // Octets 7-8. BMI
                        record.bmi = Double(try stream.readUI16()) / 100
                        // Octets 9-10. Balance
                        record.balance = Double(try stream.readUI16()) / 10
                        // Octets 11-21. Unknown
                        try stream.skip(11)
                        // Save record.
                        profile?.records.append(record)
                    }
                    throw StreamError.endOfRecords
                }
                catch {
                    switch error {
                        // End of Records and Invalid Date respresent the end of the avaliable records
                    case StreamError.endOfRecords, StreamError.invalidDate:
                        // Save profile
                        if profile != nil && profile?.isEmpty == false { profiles.append(profile!) }
                    default:
                        break
//                        handleErrors(error)
                    }
                    // Offset stream to next profile
                    try stream.skip(recordSize - stream.bytesRead)
                    // Reset byte count
                    stream.bytesRead = 0
                }
            }
            return profiles
        }
        // Handle stream errors
        catch {
//            handleErrors(error)
            return profiles
        }
    }
    
    static private func handleErrors(_ error:Error) {
        switch error {
        case StreamError.endOfFile:
            print("End of file.")
        case StreamError.endOfRecords:
            print("End of profile records.")
        case StreamError.invalidDate:
            print("Invalid date.")
        case StreamError.invalidFile:
            print("Cannot read file.")
        case StreamError.invalidLength:
            print("Error. Must read atleast 1 byte.")
        case StreamError.invalidString:
            print("Invalid string.")
        case StreamError.unknown:
            print("An unknown error has occured.")
        default:
            print(error)
        }
    }
}

struct WiiFitRecord : CustomStringConvertible {
    var date:Date!
    var weight:Double!
    var bmi:Double!
    var balance: Double!
    
    var description: String {
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        return "\(components.year!.formatted())-\(components.month!.formatted())-\(components.day!.formatted()) \(components.hour!.formatted()):\(components.minute!.formatted()):00, \(weight!.formatted())kg, \(bmi!.formatted()), \(balance!.formatted())%"
    }
}

extension Int {
    func formatted(_ length:Int = 2) -> String {
        return String(format: "%0\(length)d", self)
    }
}

extension Double {
    func formatted(_ length:Int = 3) -> String {
        return String(format: "%0\(length).2f", self)
    }
}
