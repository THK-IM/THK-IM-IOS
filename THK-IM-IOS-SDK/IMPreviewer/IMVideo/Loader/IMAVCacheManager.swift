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
import SwiftEventBus

open class IMAVCacheManager {
    
    static let customProtocol = "custom"
    static let maxPageSize: Int64 = 500 * 1024
    
    static let shared = IMAVCacheManager()
    
    private var caches = [String: IMAVCache]()
    private var tasks = [String: (AVAssetResourceLoadingRequest, IMAVCacheRangeRequest)]()
    private let locker = NSLock()
    private var token: String = ""
    private var endpoint: String = ""
    
    func initCache(token: String, endpoint: String) {
        self.token = token
        self.endpoint = endpoint
    }
    
    func getToken() -> String {
        return self.token
    }
    
    func getEndpoint() -> String {
        return self.endpoint
    }
    
    func getCacheKey(url: String) -> String {
        if url.hasSuffix(self.endpoint) {
            let urlComponents = URLComponents(string: url)
            if (urlComponents != nil && urlComponents!.queryItems != nil) {
                for it in urlComponents!.queryItems! {
                    if it.name == "id" && it.value != nil {
                        return it.value!
                    }
                }
            }
        }
        return url
    }
    
    func loadCache(_ url: String) -> IMAVCache {
        let key = self.getCacheKey(url: url)
        var cache = caches[key]
        if cache == nil {
            let cacheDir = self.cacheDir(key)
            cache = IMAVCache(cacheDir, url)
            caches[key] = cache
        }
        return cache!
    }
    
    func addRequest(_ request: AVAssetResourceLoadingRequest) -> Bool {
        locker.unlock()
        defer {locker.unlock()}
        guard let url = request.request.url?.absoluteString else {
            return false
        }
        let urlString = url.replacingOccurrences(of: IMAVCacheManager.customProtocol, with: "http")
        let originRangeString = self.getHeaderRangeValue(request)
        let cache = self.loadCache(urlString)
        let needLoadRanges = cache.getNeedLoadRanges(originRangeString)
        if needLoadRanges.count > 0 {
            // 缓存不够,计算需要下载的range
            let needLoadRangeString = self.buildRequestRangeString(needLoadRanges, IMAVCacheManager.maxPageSize)
            return self.addTask(request, needLoadRangeString, originRangeString, urlString)
        } else {
            // 缓存足够
            self.onLoadSuccess(request, cache)
            return true
        }
    }
    
    private func addTask(_ request: AVAssetResourceLoadingRequest, _ needLoadRangeString: String, _ originRangeString: String, _ urlString: String) -> Bool {
        if tasks[originRangeString] == nil {
            let rangeRequest = IMAVCacheRangeRequest(needLoadRangeString, originRangeString, urlString) {
                [weak self] success, requestRange, requestUrl, data, responseRange, responseType in
                self?.onRangeResponse(success, requestRange, requestUrl, data, responseRange, responseType)
            }
            tasks[originRangeString] = (request, rangeRequest)
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
    
    private func getHeaderRangeValue(_ request: AVAssetResourceLoadingRequest) -> String {
        let headers = request.request.headers
        let headerString = headers["Range"] != nil ? headers["Range"]! : ""
        
        let ranges = self.parserRangesFromRangeString(headerString, IMAVCacheManager.maxPageSize)
        let realRequestRangeString = self.buildRequestRangeString(ranges, IMAVCacheManager.maxPageSize)
        return realRequestRangeString
    }
    
    private func cacheDir(_ cacheKey: String) -> String {
        let dirPath = NSTemporaryDirectory() + "video/" + cacheKey.sha1Hash
        print("IMAVCacheManager \(dirPath)")
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
        if !success || data == nil || responseType == nil || responseRange == nil {
            // 失败
            onLoadFailed(key: requestRange)
        } else {
            let cache = self.loadCache(requestUrl)
            let success = cache.writeNewCache(responseRange!, responseType!, data!)
            if (success) {
                if (cache.cacheInfo.isFinished()) {
                    SwiftEventBus.post(IMAVCacheEvent, sender: cache)
                }
            }
            let taskTuple = self.tasks[requestRange]
            if taskTuple != nil {
                self.onLoadSuccess(taskTuple!.0, cache)
            }
        }
        self.tasks.removeValue(forKey: requestRange)
    }
    
    private func onLoadFailed(key: String) {
        let taskTuple = self.tasks[key]
        if taskTuple != nil {
            taskTuple!.0.finishLoading()
        }
    }
    
    private func onLoadSuccess(_ request: AVAssetResourceLoadingRequest, _ cache: IMAVCache) {
        let requestRange = self.getHeaderRangeValue(request)
        let data = cache.fetchCachedData(requestRange)
        if data != nil {
            request.contentInformationRequest?.contentLength = Int64(cache.cacheInfo.contentLength)
            request.contentInformationRequest?.contentType = cache.cacheInfo.contentType
            request.contentInformationRequest?.isByteRangeAccessSupported = true
            request.dataRequest?.respond(with: data!)
        }
        request.finishLoading()
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
        if rangesString.contains("bytes=") {
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

