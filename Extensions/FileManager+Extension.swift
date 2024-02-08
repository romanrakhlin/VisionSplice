//
//  FileManager+Extension.swift
//
//
//  Created by Roman Rakhlin on 2/6/24.
//

import Foundation

extension FileManager {
    static var documentsDirectoryURL: URL {
        if #available(iOS 16.0, *) {
            return URL.documentsDirectory
        } else {
            return FileManager.default.urls(
                for: .documentDirectory,
                in: .userDomainMask
            )[0]
        }
    }
    
    static var cachesDirectoryURL: URL {
        if #available(iOS 16.0, *) {
            return URL.cachesDirectory
        } else {
            return FileManager.default.urls(
                for: .cachesDirectory,
                in: .userDomainMask
            )[0]
        }
    }
    
    static var temporaryDirectoryURL: URL {
        if #available(iOS 16.0, *) {
            return URL.temporaryDirectory
        } else {
            return FileManager.default.temporaryDirectory
        }
    }
    
    static var homeDirectoryURL: URL {
        if #available(iOS 16.0, *) {
            return URL.homeDirectory
        } else {
            return URL(fileURLWithPath: NSHomeDirectory(), isDirectory: true)
        }
    }
    
}

extension FileManager {

    func lookupOrCreate(directoryAt url: URL) -> Bool {
        lookupOrCreate(directoryAt: url.path)
    }
    
    func lookupOrCreate(directoryAt path: String) -> Bool {
        var isDirectory : ObjCBool = false
        
        if fileExists(atPath: path, isDirectory: &isDirectory) {
            if isDirectory.boolValue {
                return true
            }
            return false
        }
        
        do {
            try createDirectory(atPath: path, withIntermediateDirectories: true, attributes: nil)
        } catch let error {
            print(error)
            return false
        }
        
        return true
    }

    func directoryExistsAtPath(_ path: String) -> Bool {
        var isDirectory = ObjCBool(true)
        let exists = fileExists(atPath: path, isDirectory: &isDirectory)
        return exists && isDirectory.boolValue
    }

    func deleteIfExists(at url: URL) {
        do {
            if fileExists(atPath: url.path) || directoryExistsAtPath(url.path) {
                try removeItem(at: url)
            }
        } catch {
            print("Could not remove file \(error.localizedDescription)")
        }
    }
}

extension FileManager {
    static let reelsWorkingDirectoryURL: URL = {
        let directoryURL = documentsDirectoryURL.appendingPathComponent("videos", isDirectory: true)
        _ = FileManager.default.lookupOrCreate(directoryAt: directoryURL)

        return directoryURL
    }()
}
