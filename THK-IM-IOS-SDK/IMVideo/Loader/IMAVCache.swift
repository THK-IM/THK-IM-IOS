//
//  IMAVCache.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/7/16.
//

import Foundation
import CocoaLumberjack

open class RangeInfo: Codable {
    var start: Int64
    var end: Int64
    init(start: Int64, end: Int64) {
        self.start = start
        self.end = end
    }
    
    enum CodingKeys: String, CodingKey {
        case start = "start"
        case end = "end"
    }
}

open class IMAVCacheInfo: Codable {
    var contentLength: Int64
    var contentType: String
    var loadedRanges: [RangeInfo]
    
    init(_ length: Int64, _ type: String, _ ranges: [RangeInfo]) {
        self.contentLength = length
        self.contentType = type
        self.loadedRanges = ranges
    }
    
    enum CodingKeys: String, CodingKey {
        case contentLength = "contentLength"
        case contentType = "contentType"
        case loadedRanges = "loadedRanges"
    }
    
    func isFinished() -> Bool {
        var s : Int64 = 0
        for r in loadedRanges {
            s += Int64(r.end - r.start) + 1
        }
        return s == self.contentLength
    }
}

class IMAVCache{
    var cacheDir: String
    var cacheFilePath: String
    var cacheInfoFilePath: String
    var cacheUrl: String
    var cacheInfo: IMAVCacheInfo
    private let lock = NSLock()
    
    init(_ cacheDir: String, _ cacheUrl: String, _ contentType: String, _ contentRange: String) {
        self.cacheDir = cacheDir
        self.cacheFilePath = "\(cacheDir)/video.tmp"
        self.cacheInfoFilePath = "\(cacheDir)/meta.json"
        self.cacheUrl = cacheUrl
        self.cacheInfo = IMAVCacheInfo(0, contentType, [])
        let (length, ranges) = self.parserResponseRange(contentRange)
        self.cacheInfo.contentLength = length
        for r in ranges {
            self.addLoadedRange(r)
        }
    }
    
    init(_ cacheDir: String, _ cacheUrl: String) throws {
        let infoFilePath = "\(cacheDir)/meta.json"
        var isDirectory: ObjCBool = false
        let existed = FileManager.default.fileExists(atPath: infoFilePath, isDirectory: &isDirectory)
        if !existed {
            throw CocoaError.error(.fileReadUnknown)
        }
        if (existed && isDirectory.boolValue) {
            try FileManager.default.removeItem(atPath: infoFilePath)
            throw CocoaError.error(.fileReadUnknown)
        }
        let cacheFilePath = "\(cacheDir)/video.tmp"
        if !FileManager.default.fileExists(atPath: cacheFilePath) {
            try FileManager.default.removeItem(atPath: infoFilePath)
            throw CocoaError.error(.fileReadUnknown)
        }
        guard let content = FileManager.default.contents(atPath: infoFilePath) else {
            throw CocoaError.error(.fileReadUnknown)
        }
        let _cacheInfo = try JSONDecoder().decode(IMAVCacheInfo.self, from: content)
        self.cacheDir = cacheDir
        self.cacheFilePath = cacheFilePath
        self.cacheInfoFilePath = infoFilePath
        self.cacheUrl = cacheUrl
        self.cacheInfo = _cacheInfo
        
    }
    
    // 返回需要加载的range和已经缓存的range
    private func getNeedLoadRange(_ range: RangeInfo) -> ([RangeInfo], [RangeInfo]) {
        return calNeedLoadRange(range, self.cacheInfo.loadedRanges)
    }
    
    // cachedRangeInfos必须要保证从小到大排序
    private func calNeedLoadRange(_ rangeInfo: RangeInfo, _ cachedRangeInfos: [RangeInfo]) -> ([RangeInfo], [RangeInfo]) {
        if cachedRangeInfos.count == 0 {
            return ([rangeInfo], [])
        }
        var needLoadRanges = [RangeInfo]()
        var localRanges = [RangeInfo]()
        var startPos = 0, endPos = cachedRangeInfos.count  - 1
        for pos in 0 ..< cachedRangeInfos.count {
            let cR = cachedRangeInfos[pos]
            if rangeInfo.start >= cR.start {
                startPos = pos
            }
        }
        
        for pos in 0 ..< cachedRangeInfos.count {
            let cR = cachedRangeInfos[pos]
            if rangeInfo.end <= cR.end {
                endPos = pos
                break
            }
        }
        
        if rangeInfo.start < cachedRangeInfos[startPos].start {
            let start = rangeInfo.start
            let end = min(cachedRangeInfos[startPos].start - 1, rangeInfo.end)
            if end >= start {
                needLoadRanges.append(RangeInfo(start: start, end: end))
            }
        }
        
        if startPos < endPos {
            for i in startPos ..< endPos {
                let start = cachedRangeInfos[i].end + 1
                let end = cachedRangeInfos[i+1].start - 1
                if end >= start {
                    needLoadRanges.append(RangeInfo(start: start, end: end))
                }
                let fetchStart = max(cachedRangeInfos[i].start, rangeInfo.start)
                let fetchEnd = min(cachedRangeInfos[i].end, rangeInfo.end)
                localRanges.append(RangeInfo(start: fetchStart, end: fetchEnd))
            }
            let fetchStart = max(cachedRangeInfos[endPos].start, rangeInfo.start)
            let fetchEnd = min(cachedRangeInfos[endPos].end, rangeInfo.end)
            localRanges.append(RangeInfo(start: fetchStart, end: fetchEnd))
        }
        
        if rangeInfo.end > cachedRangeInfos[endPos].end {
            let start = max(cachedRangeInfos[endPos].end+1, rangeInfo.start)
            let end = rangeInfo.end
            if end > start {
                needLoadRanges.append(RangeInfo(start: start, end: end))
            }
        }
        return (needLoadRanges, localRanges)
    }
    
    private func addLoadedRange(_ range: RangeInfo) {
        var pos = 0
        for p in self.cacheInfo.loadedRanges {
            if range.start <= p.start {
                if range.start == p.start && range.end > p.end {
                    pos += 1
                }
                break
            }
            pos += 1
        }
        self.cacheInfo.loadedRanges.insert(range, at: pos)
        
        var positions = [Int64]()
        for p in self.cacheInfo.loadedRanges {
            let pCount = positions.count
            if pCount == 0 {
                positions.append(p.start)
                positions.append(p.end)
            } else {
                if p.start <= positions[pCount-1] + 1 {
                    positions[pCount-1] = max(positions[pCount-1], p.end)
                } else {
                    positions.append(p.start)
                    positions.append(p.end)
                }
            }
        }
        self.cacheInfo.loadedRanges.removeAll()
        for i in 0 ..< positions.count {
            if i%2==0 {
                self.cacheInfo.loadedRanges.append(RangeInfo(start: positions[i], end: positions[i+1]))
            }
        }
    }
    
    func writeNewCache(_ contentRange: String, data: Data) -> Bool {
        lock.lock()
        defer {lock.unlock()}
        defer {
            do {
                let data = try JSONEncoder().encode(self.cacheInfo)
                if (FileManager.default.fileExists(atPath: self.cacheInfoFilePath)) {
                    try FileManager.default.removeItem(atPath: self.cacheInfoFilePath)
                }
                FileManager.default.createFile(atPath: self.cacheInfoFilePath, contents: data)
            } catch {
                DDLogError(error)
            }
        }
        var isDirectory: ObjCBool = false
        let existed = FileManager.default.fileExists(atPath: self.cacheFilePath, isDirectory: &isDirectory)
        if !existed {
            let success = FileManager.default.createFile(atPath: self.cacheFilePath, contents: data)
            if !success {
                self.cacheInfo.loadedRanges.removeAll()
                return success
            }
        }
        do {
            if (existed && isDirectory.boolValue) {
                self.cacheInfo.loadedRanges.removeAll()
                try FileManager.default.removeItem(atPath: self.cacheFilePath)
                let success = FileManager.default.createFile(atPath: self.cacheFilePath, contents: nil)
                if !success {
                    return success
                }
            }
            guard let file = FileHandle(forWritingAtPath: self.cacheFilePath) else {
                return false
            }
            let (length, ranges) = self.parserResponseRange(contentRange)
            var pos = 0
            for r in ranges {
                try file.seek(toOffset: UInt64(r.start))
                let endPos = pos+(Int(r.end-r.start)+1)
                file.write(data[pos..<endPos])
                pos = endPos
                self.addLoadedRange(r)
            }
            try file.close()
            self.cacheInfo.contentLength = length
        } catch {
            DDLogError(error)
        }
        return false
    }
    
    private func parserRequestRange(_ requestRange: String) -> [RangeInfo] {
        var rangesString = requestRange
        if rangesString.contains("bytes") {
            rangesString = String(rangesString.replacingOccurrences(of: "bytes=", with: ""))
        }
        return self.parserRanges(rangesString, self.cacheInfo.contentLength)
    }
    
    private func parserResponseRange(_ contentRange: String) -> (Int64, [RangeInfo]) {
        guard let lengthIndex = contentRange.lastIndex(of: "/") else {
            return (0, [])
        }
        let lengthString = contentRange.suffix(from: contentRange.index(lengthIndex, offsetBy: 1))
        guard let length = Int64(lengthString) else {
            return (0, [])
        }
        var rangesString = String(contentRange.prefix(upTo: contentRange.index(lengthIndex, offsetBy: 0)))
        if rangesString.contains("bytes") {
            rangesString = String(rangesString.replacingOccurrences(of: "bytes", with: ""))
        }
        rangesString = String(rangesString.replacingOccurrences(of: " ", with: ""))
        let rangeInfos = self.parserRanges(rangesString, length)
        return (length, rangeInfos)
    }
    
    private func parserRanges(_ rangesString: String, _ contentLength: Int64) -> [RangeInfo] {
        let ranges = rangesString.split(separator: ",")
        var rangeInfos = [RangeInfo]()
        for r in ranges {
            if r.contains("-") {
                var start: Int64? = nil, end: Int64? = nil
                let contents = r.split(separator: "-")
                if contents.count == 1 {
                    if r.hasPrefix("-") {
                        end = Int64(contents[0])
                    } else {
                        start = Int64(contents[0])
                    }
                } else if contents.count == 2 {
                    start = Int64(contents[0])
                    end = Int64(contents[1])
                } else {
                    break
                }
                if start == nil {
                    start = 0
                }
                if end == nil {
                    end = contentLength - 1
                }
                rangeInfos.append(RangeInfo(start: start!, end: end!))
            }
        }
        return rangeInfos
    }
    
    func getNeedLoadRanges(_ requestRange: String) -> [RangeInfo] {
        lock.lock()
        defer {lock.unlock()}
        let ranges = self.parserRequestRange(requestRange)
        var requestRanges = [RangeInfo]()
        for r in ranges {
            let (r1, _) = self.getNeedLoadRange(r)
            requestRanges.append(contentsOf: r1)
        }
        return requestRanges
    }
    
    func fetchCachedData(_ requestRange: String) -> Data? {
        lock.lock()
        defer {lock.unlock()}
        let ranges = self.parserRequestRange(requestRange)
        var data = Data()
        guard let tmpFile = FileHandle(forReadingAtPath: self.cacheFilePath) else {
            return nil
        }
//        let maxLength = 1024 * 100 // 一次最多返回100k数据
        do {
            for range in ranges {
                let (r1, _) = self.getNeedLoadRange(range)
                if r1.count == 0 {
                    try tmpFile.seek(toOffset: UInt64(range.start))
                    var length = Int(range.end - range.start) + 1
//                    if data.count + length > maxLength {
//                        length = maxLength - data.count
//                    }
                    let d = tmpFile.readData(ofLength: length)
                    data.append(d)
//                    if data.count >= maxLength {
//                        break
//                    }
                } else {
                    // 无法补齐
                    data.removeAll()
                    break
                }
            }
            try tmpFile.close()
        } catch {
            DDLogError(error)
        }
        return data.count > 0 ? data: nil
    }
}
