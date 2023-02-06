//
//  Webservice.swift
//  Santa
//
//  Created by Christian Braun on 05.12.19.
//

import UIKit

public protocol RequestAuthorization {
    func authorize(
        _ request: URLRequest,
        for resource: Resource,
        completion: @escaping (Result<URLRequest, Error>) -> Void)
}

public enum NetworkError: LocalizedError, Equatable {
    case parseUrl
    case parseData(message: String)
    case failedAuthorization
    case badResponseCode(code: Int)
    case noInternetConnectivity
    case notFound

    public var errorDescription: String? {
        switch self {
        case .parseUrl:
            return "A problem with the server address occured"
        case .parseData(let message):
            return "Can't parse data: \(message)"
        case .failedAuthorization:
            return "Unable to authorize"
        case .badResponseCode(let code):
            return "Server responded with unexpected response code \(code)"
        case .noInternetConnectivity:
            return "No internet connection"
        case .notFound:
            return "The requested data does not exist"
        }
    }
}

public protocol WebserviceDownloadTaskDelegate: AnyObject {
    func webservice(_ sender: Webservice, didFinishDownload url: String, atLocation location: URL, fileName: String)
    func webservice(_ sender: Webservice, didErrorDownload url: String, with error: Error, for taskIdentifier: TaskIdentifier)
}

public protocol WebserviceUploadTaskDelegate: AnyObject {
    func webservice(_ sender: Webservice, didFinishUpload url: String, forFilePath filepath: URL, taskIdentifier: TaskIdentifier, data: Data?)
    func webservice(_ sender: Webservice, didErrorUpload url: String, with error: Error, for taskIdentifier: TaskIdentifier, data: Data?)
}

public protocol WebserviceDelegate: AnyObject {
    func webservice(_ sender: Webservice, error: Error, for request: URLRequest, with data: Data?, taskIdentifier: TaskIdentifier)
}

public protocol Webservice {
    var delegate: WebserviceDelegate? { get set }
    var uploadDelegate: WebserviceUploadTaskDelegate? { get set }
    var downloadDelegate: WebserviceDownloadTaskDelegate? { get set }
    var backgroundDownloadCompletionHandler: (() -> Void)? { get set }
    var authorization: RequestAuthorization? { get set }
    var urlSession: URLSession { get set }
    var downAndUploadURLSession: URLSession { get set }

    func load<A>(resource: DataResource<A>, completion: @escaping (A?, URLResponse?, Error?) -> Void)
    func load<A>(resource: DataResource<A>, completion: @escaping (A?, Error?) -> Void)
    func load(resource: DownloadResource, onPreparationError: @escaping (Error) -> Void)
    func load(resource: UploadResource, onPreparationError: @escaping (Error) -> Void)
    func reset()
    func cancelTask(for uuid: UUID)
    func isTaskActive(for uuid: UUID) -> Bool
    func isTaskActive(for url: URL) -> Bool
    func isTaskActive(forFileName fileName: String) -> Bool
}

public typealias ImplWebservice = DefaultWebservice


public final class DefaultWebservice: NSObject, Webservice {
    public weak var uploadDelegate: WebserviceUploadTaskDelegate?
    public weak var downloadDelegate: WebserviceDownloadTaskDelegate?
    public var backgroundDownloadCompletionHandler: (() -> Void)?
    public weak var delegate: WebserviceDelegate?
    public var authorization: RequestAuthorization?

    public var imageCache = ImageCache()
    fileprivate var activeTasks = [UUID: URLSessionTask]()
    fileprivate var uploadTaskDataForTaskUUID = [UUID: Data]()
    public lazy var urlSession: URLSession = {
        URLSession(
            configuration: URLSessionConfiguration.default,
            delegate: self,
            delegateQueue: nil)
    }()

    public lazy var downAndUploadURLSession: URLSession = {
        let config = URLSessionConfiguration.background(withIdentifier: "SantaBackgroundURLSession")
        config.sessionSendsLaunchEvents = true
        config.isDiscretionary = false
        config.waitsForConnectivity = true
        return URLSession(
            configuration: config,
            delegate: self,
            delegateQueue: nil)
    }()

    public init(useBackgroundURLSession: Bool = false) {
        super.init()
        // Overrides the configured session
        if useBackgroundURLSession == false {
           downAndUploadURLSession = urlSession
        }

        populateActiveTasks(for: urlSession)
        populateActiveTasks(for: downAndUploadURLSession)
    }

    public func load<A>(resource: DataResource<A>, completion: @escaping (A?, URLResponse?, Error?) -> Void) {
        guard let request = createRequest(fromResource: resource) else {
            completion(nil, nil, NetworkError.parseUrl)
            return
        }

        if let completion = completion as? (UIImage?, URLResponse?, Error?) -> Void,
            let image = imageCache.get(url: resource.url) {
            completion(image, nil, nil)
            return
        }

        if resource.authorizationNeeded {
            guard let authorization = authorization else {
                assertionFailure("Authorization must be set if a resource requires authorization")
                return
            }
            authorization.authorize(request, for: resource) { result in
                switch result {
                case .success(let authedRequest):
                    self.doRequest(
                        resource: resource,
                        authedRequest,
                        completion: completion)
                case .failure(let error):
                    completion(nil, nil, error)
                }
            }
        } else {
            doRequest(resource: resource, request, completion: completion)
        }
    }

    /// @param completion: Both arguments (data and error) may be nil (for example, when a resource gets deleted)
    public func load<A>(resource: DataResource<A>, completion: @escaping (A?, Error?) -> Void) {
        load(resource: resource) { result, _, error in completion(result, error) }
    }

    public func cancelTask(for uuid: UUID) {
        activeTasks[uuid]?.cancel()
        activeTasks.removeValue(forKey: uuid)
    }

    public func isTaskActive(for uuid: UUID) -> Bool {
        return activeTasks[uuid] != nil
    }

    public func isTaskActive(for url: URL) -> Bool {
        for urlTask in activeTasks.values {
            guard let requestUrl = urlTask.originalRequest?.url else {
                continue
            }

            if url == requestUrl {
                return true
            }
        }

        return false
    }

    public func isTaskActive(forFileName fileName: String) -> Bool {
        activeTasks.values.contains { TaskIdentifier(taskDescription: $0.taskDescription)?.additional == fileName }
    }

    public func reset() {
        resetUrlTasks()
        imageCache.invalidate()
        guard let cookieStorage = urlSession.configuration.httpCookieStorage, let cookies = cookieStorage.cookies else {
            return
        }
        for cookie in cookies {
            cookieStorage.deleteCookie(cookie)
        }
    }

    fileprivate func createRequest(fromResource resource: Resource) -> URLRequest? {
        guard let url = URL(string: resource.url) else { return nil }
        var request = URLRequest(url: url)
        request.httpMethod = resource.method.rawValue
        if resource.headers.accept != HTTPHeader.acceptNone {
            request.addValue(resource.headers.accept, forHTTPHeaderField: "Accept")
        }
        if resource.headers.contentType != HTTPHeader.contentTypeNone {
            request.addValue(resource.headers.contentType, forHTTPHeaderField: "Content-Type")
        }
        for header in resource.headers.other {
            request.addValue(header.value, forHTTPHeaderField: header.key)
        }
        request.httpBody = resource.body

        return request
    }

    fileprivate func doRequest<A>(resource: DataResource<A>, _ request: URLRequest, completion: @escaping (A?, URLResponse?, Error?) -> Void) {
        let dataTask = urlSession.dataTask(with: request) { data, response, error in
            let task = self.activeTasks.removeValue(forKey: resource.uuid)
            guard let taskIdentifier = TaskIdentifier(taskDescription: task?.taskDescription) else {
                assertionFailure("Task description must contain custom task identifier")
                return
            }
            if let error = self.errorForResponseAndError(response, error) {
                completion(nil, response, error)
                self.delegate?.webservice(self, error: error, for: request, with: data, taskIdentifier: taskIdentifier)
                return
            }
            guard let data = data else {
                completion(nil, response, nil)
                return
            }
            do {
                let result = try resource.parseData(data)
                if let image = result as? UIImage {
                    self.imageCache.add(url: resource.url, image: image)
                }
                completion(result, response, nil)
            } catch {
                completion(nil, response, NetworkError.parseData(message: error.localizedDescription))
            }
        }
        dataTask.taskDescription = TaskIdentifier(taskType: .data, uuid: resource.uuid, additional: nil).stringValue
        activeTasks[resource.uuid] = dataTask
        dataTask.resume()
    }

    fileprivate func errorForResponseAndError(_ response: URLResponse?, _ error: Error?) -> Error? {
        // explicitly handle the case "no internet connectivity"
        if let error = error as NSError?,
            error.domain == NSURLErrorDomain &&
                error.code == NSURLErrorNotConnectedToInternet {
            return NetworkError.noInternetConnectivity
        }

        guard error == nil  else {
            return error
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            return NetworkError.badResponseCode(code: 0)
        }

        // explicitly handle the case 'unauthorized'
        guard httpResponse.statusCode != 401 else {
            return NetworkError.failedAuthorization
        }

        guard httpResponse.statusCode != 404 else {
            return NetworkError.notFound
        }

        guard httpResponse.statusCode >= 200 && httpResponse.statusCode < 300 else {
            return NetworkError.badResponseCode(code: httpResponse.statusCode)
        }

        return nil
    }

    public func resetUrlTasks() {
        cancelTasks(for: urlSession)
        cancelTasks(for: downAndUploadURLSession)
    }

    fileprivate func cancelTasks(for urlSession: URLSession) {
        urlSession.getAllTasks { tasks in
            tasks.forEach { $0.cancel() }
        }
    }

    fileprivate func populateActiveTasks(for urlSession: URLSession) {
        urlSession.getAllTasks { tasks in
            tasks.forEach { task in
                guard let identifier = TaskIdentifier(taskDescription: task.taskDescription)?.uuid else {
                    return
                }
                self.activeTasks[identifier] = task
            }
        }
    }
}

public extension DefaultWebservice {
    func load(resource: DownloadResource, onPreparationError: @escaping (Error) -> Void) {
        guard let request = createRequest(fromResource: resource) else {
            onPreparationError(NetworkError.parseUrl)
            return
        }

        if resource.authorizationNeeded {
            guard let authorization = authorization else {
                assertionFailure("Authorization must be set if a resource requires authorization")
                return
            }
            authorization.authorize(request, for: resource) { result in
                switch result {
                case .success(let authedRequest):
                    self.doRequest(
                        resource: resource,
                        authedRequest)
                case .failure(let error):
                    onPreparationError(error)
                }
            }
        } else {
            doRequest(resource: resource, request)
        }
    }

    fileprivate func doRequest(
        resource: DownloadResource ,
        _ request: URLRequest) {
            let downloadTask = downAndUploadURLSession.downloadTask(with: request)
            downloadTask.taskDescription = TaskIdentifier(taskType: .download, uuid: resource.uuid, additional: resource.fileName).stringValue
            activeTasks[resource.uuid] = downloadTask
            downloadTask.resume()
    }
}


public extension DefaultWebservice {
    func load(resource: UploadResource, onPreparationError: @escaping (Error) -> Void) {
        guard let request = createRequest(fromResource: resource) else {
            onPreparationError(NetworkError.parseUrl)
            return
        }

        if resource.authorizationNeeded {
            guard let authorization = authorization else {
                assertionFailure("Authorization must be set if a resource requires authorization")
                return
            }
            authorization.authorize(request, for: resource) { result in
                switch result {
                case .success(let authedRequest):
                    self.doRequest(
                        resource: resource,
                        authedRequest)
                case .failure(let error):
                    onPreparationError(error)
                }
            }
        } else {
            doRequest(resource: resource, request)
        }
    }

    fileprivate func doRequest(
        resource: UploadResource,
        _ request: URLRequest) {
            let uploadTask = downAndUploadURLSession.uploadTask(with: request, fromFile: resource.filePath)
            uploadTask.taskDescription = TaskIdentifier(taskType: .upload, uuid: resource.uuid, additional: resource.filePath.absoluteString).stringValue
            activeTasks[resource.uuid] = uploadTask
            uploadTask.resume()
    }
}


extension DefaultWebservice: URLSessionDownloadDelegate, URLSessionDataDelegate {
    // MARK: - URLSessionDownloadDelegate

    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        guard let taskIdentifier = TaskIdentifier(taskDescription: dataTask.taskDescription),
        taskIdentifier.type == .upload else {
            return
        }

        uploadTaskDataForTaskUUID[taskIdentifier.uuid] = data
    }

    public func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didFinishDownloadingTo location: URL) {
            guard let taskIdentifier = TaskIdentifier(taskDescription: downloadTask.taskDescription),
            let fileName = taskIdentifier.additional else {
                assertionFailure("Unable to get filename for download task")
                return
            }
            if let error = self.errorForResponseAndError(downloadTask.response, nil) {
                return
            }
            guard let url = downloadTask.originalRequest?.url else {
                preconditionFailure("Download task must contain url")
            }
            downloadDelegate?.webservice(self, didFinishDownload: url.absoluteString, atLocation: location, fileName: fileName)
        }

    public func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        didCompleteWithError error: Error?) {
            guard let taskIdentifier = TaskIdentifier(taskDescription: task.taskDescription) else {
                assertionFailure("Unable to get custom task identifier from task \(task.taskDescription ?? "No description set")")
                return
            }
            activeTasks.removeValue(forKey: taskIdentifier.uuid)

            guard let url = task.originalRequest?.url else {
                preconditionFailure("Download task must contain url")
            }

            if let error = errorForResponseAndError(task.response, error) {
                switch taskIdentifier.type {
                case .download:
                    downloadDelegate?.webservice(self, didErrorDownload: url.absoluteString, with: error, for: taskIdentifier)
                case .upload:
                    uploadDelegate?.webservice(self, didErrorUpload: url.absoluteString, with: error, for: taskIdentifier, data: uploadTaskDataForTaskUUID.removeValue(forKey: taskIdentifier.uuid))
                case .data:
                    break
                }
                return
            }

            if taskIdentifier.type == .upload,
               let filePathString = taskIdentifier.additional,
               let url = URL(string: filePathString) {
                uploadDelegate?.webservice(
                    self,
                    didFinishUpload: url.absoluteString,
                    forFilePath: url,
                    taskIdentifier: taskIdentifier,
                    data: uploadTaskDataForTaskUUID.removeValue(forKey: taskIdentifier.uuid)
                )
            }
        }

    public func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        guard session == downAndUploadURLSession else {
            return
        }
        DispatchQueue.main.async {
            debugPrint("Background downloads finished")
            self.backgroundDownloadCompletionHandler?()
        }
    }
}
