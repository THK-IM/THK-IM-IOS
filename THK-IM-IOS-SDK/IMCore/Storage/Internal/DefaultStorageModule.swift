//
//  DefaultStorageModule.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/6/9.
//

import Foundation
import CocoaLumberjack

public class DefaultStorageModule : StorageModule {
    
    private let rootPath: String
    
    init(_ uId: Int64) {
        rootPath = NSHomeDirectory() + "/Documents/im/\(uId)"
    }
    
    
    // 删除文件
    public func removeFile(_ fullPath: String) {
        do {
            try FileManager.default.removeItem(atPath: fullPath)
        } catch {
            DDLogError("removeFile, path:\(fullPath), error: \(error)")
        }
    }
    
    public func sandboxFilePath(_ fullPath: String) -> String {
        var pos = -1
        if let range = fullPath.range(of:"Documents", options: .literal ) {
            if !range.isEmpty {
                pos = fullPath.distance(from: fullPath.startIndex, to:range.lowerBound)
            }
        }
        if (pos == -1) {
            return fullPath
        } else {
            let subPathIndex = fullPath.index(fullPath.startIndex, offsetBy: pos)
            let s = fullPath[subPathIndex..<fullPath.endIndex]
            return "\(NSHomeDirectory())/\(String(s))"
        }
    }
    
    public func getFileExt(_ path: String) -> (String, String) {
        if let dotIndex = path.lastIndex(of: ".") {
            let extIndex = path.index(dotIndex, offsetBy: 1)
            let ext = path[extIndex..<path.endIndex]
            let name = path[..<dotIndex]
            return (String(name), String(ext))
        } else {
            return (path, "")
        }
    }
    
    public func getPathsFromFullPath(_ fullPath: String) -> (String, String) {
        if let biasIndex = fullPath.lastIndex(of: "/") {
            let nameIndex = fullPath.index(biasIndex, offsetBy: 1)
            let name = fullPath[nameIndex..<fullPath.endIndex]
            let path = fullPath[..<biasIndex]
            return (String(path), String(name))
        } else {
            return ("", fullPath)
        }
    }
    
    public func getFileExtFromUrl(_ url: String) -> String {
        let tuple = self.getFileExt(url)
        return tuple.1
    }
    
    public func saveMediaDataInto(_ fullPath: String, _ data: Data) throws {
        let fileManager = FileManager.default
        let srcExist = fileManager.fileExists(atPath: fullPath)
        if srcExist {
            throw CocoaError.error(.fileWriteFileExists)
        }
        
        let success = fileManager.createFile(atPath: fullPath, contents: data)
        if (!success) {
            throw CocoaError(.fileWriteUnknown)
        }
    }
    
    public func copyFile(_ srcPath: String, _ dePath: String) throws {
        let fileManager = FileManager.default
        var srcIsDir: ObjCBool = false
        let srcExist = fileManager.fileExists(atPath: srcPath, isDirectory: &srcIsDir)
        if srcExist {
            if (srcIsDir.boolValue) {
                throw CocoaError.error(.fileReadNoSuchFile, userInfo: [NSFilePathErrorKey: srcPath])
            }
        } else {
            throw CocoaError.error(.fileReadNoSuchFile, userInfo: [NSFilePathErrorKey: srcPath])
        }
        
        var deIsDir: ObjCBool = false
        let deExist = fileManager.fileExists(atPath: dePath, isDirectory: &deIsDir)
        if deExist {
            if (deIsDir.boolValue) {
                throw CocoaError.error(.fileReadNoSuchFile, userInfo: [NSFilePathErrorKey: dePath])
            } else {
                try fileManager.removeItem(atPath: dePath)
            }
        }
        
        try fileManager.copyItem(atPath: srcPath, toPath: dePath)
    }
    
    public func allocSessionFilePath(_ sId: Int64,  _ fileName: String, _ format: String) -> String {
        let fileRootPath = "\(getSessionRootPath(sId))/\(format)"
        let fileManager = FileManager.default
        var isDir: ObjCBool = false
        let exist = fileManager.fileExists(atPath: fileRootPath, isDirectory: &isDir)
        if exist {
            if isDir.boolValue {
                let tuple = getFileExt(fileName)
                let name = tuple.0
                var ext =  ".\(tuple.1)"
                if (tuple.1.length == 0) {
                    ext = ""
                }
                let fullPath = "\(fileRootPath)/\(name)"
                var i: Int? = nil
                while true {
                    if (i == nil) {
                        let filePath = "\(fullPath)\(ext)"
                        if (fileManager.fileExists(atPath: filePath)) {
                            i = 1
                        } else {
                            return filePath
                        }
                    } else {
                        let filePath = "\(fullPath).\(i!)\(ext)"
                        if (fileManager.fileExists(atPath: filePath)) {
                            i = i! + 1
                        } else {
                            return filePath
                        }
                    }
                }
            } else {
                do {
                    try fileManager.removeItem(atPath: fileRootPath)
                } catch {
                    DDLogError(error)
                }
            }
        }
        do {
            try fileManager.createDirectory(atPath: fileRootPath, withIntermediateDirectories: true)
        } catch {
            DDLogError(error)
        }
        
        return "\(fileRootPath)/\(fileName)"
        
    }
    
    private func getSessionRootPath(_ sId: Int64) -> String {
        return "\(rootPath)/session-\(sId)"
    }
    
    public func isAssignedPath(_ path: String, _ format: String, _ sId: Int64) -> Bool {
        let p = "\(getSessionRootPath(sId))/\(format)"
        return path.starts(with: p)
    }
    
    public func getSessionCacheFiles(_ format: String, _ sId: Int64) -> Array<String> {
        return Array()
    }
    
    public func getSessionCacheSize(_ sId: Int64) -> Int64 {
        return 0
    }
    
    
}
