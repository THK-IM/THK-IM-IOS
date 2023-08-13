//
//  IMAVCacheManager.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/7/16.
//
import Foundation
import Alamofire
import AVFoundation
import CocoaLumberjack

open class IMAVCacheManager {
    
    static let customProtocol = "custom"
    static let notifyName = Notification.Name(rawValue: "IMAVCacheNotification")
    static let maxPageSize: Int64 = 500 * 1024
    
    static let shared = IMAVCacheManager()
    
    private var caches = [String: IMAVCache]()
    private var tasks = [String: (AVAssetResourceLoadingRequest, IMAVCacheRangeRequest)]()
    private let locker = NSLock()
    
    private init() {
    }
    
    func registerListener() {
        
    }
    
    func addRequest(_ request: AVAssetResourceLoadingRequest) -> Bool {
        locker.unlock()
        defer {locker.unlock()}
        guard let url = self.getUrl(request) else {
            return false
        }
        let urlString = url.replacingOccurrences(of: IMAVCacheManager.customProtocol, with: "http")
        let requestRangeString = self.getHeaderRangeValue(request)
        var result = false
        var cache = caches[urlString]
        if cache == nil {
            cache = self.loadCache(urlString)
            caches[urlString] = cache
        }
        if cache == nil {
            result = self.addTask(request, requestRangeString, requestRangeString, urlString)
        } else {
            let needLoadRanges = cache!.getNeedLoadRanges(requestRangeString)
            if needLoadRanges.count > 0 { // 缓存不够,计算需要下载的range
                let partRangeString = self.buildRequestRangeString(needLoadRanges, IMAVCacheManager.maxPageSize)
                result = self.addTask(request, partRangeString, requestRangeString, urlString)
            } else { // 缓存足够
                self.responseData(request, cache!)
                result = true
            }
        }
        return result
    }
    
    private func loadCache(_ urlString: String) -> IMAVCache? {
        let cacheDir = self.cacheDir(urlString)
        do {
            let cache = try IMAVCache(cacheDir, urlString)
            return cache
        } catch {
            DDLogError(error)
            return nil
        }
    }
    
    private func addTask(_ request: AVAssetResourceLoadingRequest,_ requestRangeString: String, _ originRequestString: String, _ urlString: String) -> Bool {
        if tasks[originRequestString] == nil {
            let rangeRequest = IMAVCacheRangeRequest(requestRangeString, originRequestString, urlString) {
                [weak self] success, requestRange, requestUrl, data, responseRange, responseType in
                self?.onRangeResponse(success, requestRange, requestUrl, data, responseRange, responseType)
            }
            tasks[originRequestString] = (request, rangeRequest)
            rangeRequest.startDownload()
            return true
        } else {
            return false
        }
    }
    
    func cancelRequest(_ request: AVAssetResourceLoadingRequest) {
        locker.unlock()
        defer {locker.unlock()}
        let requestRangeString = self.getHeaderRangeValue(request)
        guard let task = tasks[requestRangeString] else {
            return
        }
        if task.0 == request {
            task.1.cancel()
        }
        tasks.removeValue(forKey: requestRangeString)
    }
    
    private func getUrl(_ request: AVAssetResourceLoadingRequest) -> String? {
        return request.request.url?.absoluteString
    }
    
    private func getHeaderRangeValue(_ request: AVAssetResourceLoadingRequest) -> String {
        let headers = request.request.headers
        let headerString = headers["Range"] != nil ? headers["Range"]! : ""
        
        let ranges = self.parserRangesFromRangeString(headerString, IMAVCacheManager.maxPageSize)
        let realRequestRangeString = self.buildRequestRangeString(ranges, IMAVCacheManager.maxPageSize)
        return realRequestRangeString
    }
    
    private func cacheDir(_ requestUrl: String) -> String {
        let dirPath = NSTemporaryDirectory() + "video/" + requestUrl.hash_256
//        let name = String().random(4)
//        let dirPath = NSTemporaryDirectory() + "video/" + name
        
        var isDir: ObjCBool = false
        let exist =  FileManager.default.fileExists(atPath: dirPath, isDirectory: &isDir)
        do {
            if !exist {
                try FileManager.default.createDirectory(atPath: dirPath, withIntermediateDirectories: true)
            } else {
                if !isDir.boolValue {
                    try FileManager.default.removeItem(atPath: dirPath)
                    try FileManager.default.createDirectory(atPath: dirPath, withIntermediateDirectories: true)
                }
            }
        } catch {
            DDLogError(error)
        }
        return dirPath
    }
    
    private func onRangeResponse(_ success: Bool, _ requestRange: String , _ requestUrl: String, _ data: Data?, _ responseRange: String?, _ responseType :String?) {
        if !success {
            // 失败
            removeTask(key: requestRange)
        } else {
            if data == nil || responseType == nil || responseRange == nil {
                removeTask(key: requestRange)
                return
            }
            var cache = self.caches[requestUrl]
            if cache == nil {
                cache = IMAVCache(self.cacheDir(requestUrl), requestUrl, responseType!, responseRange!)
                self.caches[requestUrl] = cache
            }
            _ = self.caches[requestUrl]?.writeNewCache(responseRange!, data: data!)
            let taskTuple = self.tasks[requestRange]
            if taskTuple != nil {
                self.responseData(taskTuple!.0, cache!)
            }
            self.tasks.removeValue(forKey: requestRange)
        }
    }
    
    private func removeTask(key: String) {
        let taskTuple = self.tasks[key]
        if taskTuple != nil {
            taskTuple!.0.finishLoading()
            self.tasks.removeValue(forKey: key)
        }
    }
    
    private func responseData(_ request: AVAssetResourceLoadingRequest, _ cache: IMAVCache) {
        let requestRange = self.getHeaderRangeValue(request)
        let data = cache.fetchCachedData(requestRange)
        if data != nil {
            request.contentInformationRequest?.contentLength = Int64(cache.cacheInfo.contentLength)
            request.contentInformationRequest?.contentType = cache.cacheInfo.contentType
            request.contentInformationRequest?.isByteRangeAccessSupported = true
            request.dataRequest?.respond(with: data!)
        }
        request.finishLoading()
        
        var notification = Notification(name: IMAVCacheManager.notifyName)
        var value = [String: Any]()
        value["info"] = cache.cacheInfo
        value["remoteUrl"] = cache.cacheUrl
        value["localPath"] = cache.cacheFilePath
        notification.userInfo = value
        NotificationCenter.default.post(notification)
    }
    
    private func buildRequestRangeString(_ ranges: [RangeInfo], _ max: Int64) -> String {
        var result = "bytes="
        var pos = 0
        for r in ranges {
            var length = r.end - r.start
            if length > max {
                length = max
            }
            result.append("\(r.start)-\(r.start+length)")
            if pos < ranges.count - 1 {
                result.append(",")
            }
            pos += 1
        }
        return result
    }
    
    private func parserRangesFromRangeString(_ rangeString: String, _ max: Int64) -> [RangeInfo] {
        var rangesString = rangeString
        if rangesString.contains("bytes") {
            rangesString = String(rangesString.replacingOccurrences(of: "bytes=", with: ""))
        }
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
                    end = start! + max
                }
                if end! - start! > max {
                    end = start! + max
                }
                rangeInfos.append(RangeInfo(start: start!, end: end!))
            }
        }
        return rangeInfos
    }
    
}

