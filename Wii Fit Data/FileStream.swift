//
//  FileStream.swift
//  Wii Fit Data
//
//  Created by Tristan Beaton on 8/01/18.
//  Copyright © 2018 Tristan Beaton. All rights reserved.
//

import Foundation

enum StreamError: Error {
    case endOfFile
    case unknown
    case invalidFile
    case invalidLength
    case invalidDate
    case invalidString
    case endOfRecords
}
class WiiFileStream {
    
    var stream: InputStream!
    private(set) var totalBytesRead = 0 {
        willSet {
            bytesRead += newValue - totalBytesRead
        }
    }
    var bytesRead = 0
    
    var hasBytesAvailable: Bool { return stream.hasBytesAvailable }
    
    init(fileAtPath: String) throws {
        if let stream = InputStream(fileAtPath: path) {
            stream.open()
            self.stream = stream
            return
        }
        throw StreamError.invalidFile
    }
    
    deinit {
        stream.close()
    }
    
    // MARK: Helper Methods
    func readByte() throws -> UInt8 {
        var buffer = UInt8()
        let response = stream.read(&buffer, maxLength: MemoryLayout<UInt8>.size)
        switch response {
            case 0: throw StreamError.endOfFile
            case -1: throw StreamError.unknown
            default: break
        }
        totalBytesRead += 1
        return buffer
    }
    
    func readBytes(_ length:Int) throws -> Array<UInt8> {
        if length < 0 { print(length); throw StreamError.invalidLength }
        var buffer = Array<UInt8>(repeating: 0, count: length)
        let response = stream.read(&buffer, maxLength: MemoryLayout<UInt8>.size * length)
        switch response {
            case 0: throw StreamError.endOfFile
            case -1: throw StreamError.unknown
            default: break
        }
        totalBytesRead += buffer.count
        return buffer
    }
    
    func skip(_ length:Int = 1) throws  {
        let _ =  try self.readBytes(length)
    }
    
    private func readInt(_ length:Int) throws -> Array<Int> {
        let bytes = try self.readBytes(length)
        return bytes.map{ return Int($0) }
    }
    
    // MARK: Signed Integers
    func readInt8() throws -> Int {
        return Int(try self.readByte())
    }
    
    func readInt16() throws -> Int {
        let data = try self.readInt(2)
        let value = 1 - ((data[0] & 128) >> 6) * (data[0] & 127) << 8 | data[1]
        return Int(value)
    }
    
    func readInt32() throws -> Int32 {
        let data = try self.readInt(4)
        let value = 1 - ((data[0] & 128) >> 6) * (data[0] & 127) << 24 | data[1] << 16 | data[2] << 8 | data[3]
        return Int32(value)
    }
    
    // MARK: Unsigned Integers
    func readUI16() throws -> UInt16 {
        let bytes = try self.readBytes(2).map { UInt16($0) }
        return bytes[0] << 8 | bytes[1]
    }
    
    func readUI32() throws -> UInt32 {
        var bytes = try self.readBytes(4).map { UInt32($0) }
        return bytes[0] << 24 | bytes[1] << 16  | bytes[2] << 8 | bytes[3]
    }
    
    func readUI64() throws -> UInt64 {
        let bytes = try self.readBytes(8).map { UInt64($0) }
        return bytes[0] << 56 | bytes[1] << 48 | bytes[2] << 40 | bytes[3] << 32 | bytes[4] << 24 | bytes[5] << 16 | bytes[6] << 8 | bytes[7]
    }
    
    // MARK: Strings
    func readString(_ length:Int) throws -> String {
        let bytes = try self.readBytes(length)
        if let str = String(bytes: bytes, encoding: .utf8), str.isEmpty == false {
            return str
        }
        throw StreamError.invalidString
    }
    
    // MARK: Date
    func readBitfieldDate() throws -> Date {
        let bytes = try self.readUI32()
        let components = DateComponents(year: Int(bytes >> 20 & 0x7ff),
                                        month: Int((bytes >> 16 & 0xf) + 1),
                                        day: Int(bytes >> 11 & 0x1f),
                                        hour: Int(bytes >> 6 & 0x1f),
                                        minute: Int(bytes & 0x3f))
        if components.year! < 1900 { throw StreamError.invalidDate }
        if let date = Calendar(identifier: .gregorian).date(from: components) { return date }
        throw StreamError.invalidDate
    }
    
    func readBCDDate() throws -> (year:Int, month:Int, day:Int) {
        let bytes = try self.readUI16()
        let thousands = Int(bytes >> 12 & 0x0f)
        let hundreds = Int(bytes >> 8 & 0x0f)
        let tens = Int(bytes >> 4 & 0x0f)
        let ones = Int(bytes & 0x0f)
        let year = (thousands * 1000) + (hundreds * 100) + (tens * 10) + ones
        let month = try self.readInt8()
        let day = try self.readInt8()
        print(String(month, radix: 2),String(day, radix: 2))
        return (year, month, day)
    }
}
