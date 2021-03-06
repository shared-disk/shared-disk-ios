//
//  GoogleDriveService.swift
//  shared-disk (iOS)
//
//  Created by Artem Rylov on 22.05.2021.
//

import Foundation

class GoogleDriveService {
    
    private let serverService = BaseAPIService(stringAddress: "http://193.187.174.20")
    
    private let googleService = BaseAPIService(stringAddress: "https://www.googleapis.com")
    
    
    func files(taskId: Int?, folderName: String, in folder: String = "root", completion: @escaping (Result<[FileItem], AppError>) -> Void) {
        serverService.load(
            FilesResponse.self,
            method: .get,
            path: "/files",
            token: UserStorage.myToken,
            queryParams: ["folder": folder],
            completion: { fileResponseResult in
                if let t = taskId {
                    print("protocolVisitFolder start")
                    MyAPIServic().protocolVisitFolder(
                        taskId: t,
                        folderName: folderName,
                        completion: { _ in }
                    )
                }
                switch fileResponseResult {
                case .failure(let error):
                    completion(.failure(error))
                case .success(let fileResponse):
                    completion(.success(fileResponse.files))
                }
            }
        )
    }
    
    func fileRevisions(fileID: String, completion: @escaping (Result<[FileRevision], AppError>) -> Void) {
        googleService.load(
            FileRevisionResponse.self,
            method: .get,
            path: "/drive/v3/files/\(fileID)/revisions",
            token: UserStorage.googleToken,
            queryParams: ["fields": "*"],
            completion: { result in
                switch result {
                case .failure(let error):
                    completion(.failure(error))
                case .success(let response):
                    completion(.success(response.revisions))
                }
            }
        )
    }
    
    func refreshToken(completion: @escaping (Result<URL, AppError>) -> Void) {
        serverService.load(
            AuthUrlResponse.self,
            method: .get,
            path: "/refresh_authorize/google_drive",
            token: UserStorage.myToken,
            completion: { result in
                switch result {
                case .failure(let error):
                    completion(.failure(error))
                case .success(let response):
                    completion(.success(response.authorizationUrl))
                }
            }
        )
    }
    
    func authGoogleDrive(completion: @escaping (Result<Bool, AppError>) -> Void) {
        serverService.load(
            TokenResponse.self,
            method: .get,
            path: "/authorize/google_drive",
            token: UserStorage.myToken,
            completion: { result in
                switch result {
                case .failure(let error):
                    completion(.failure(error))
                case .success(let response):
                    UserStorage.googleToken = response.token
                    completion(.success(true))
                }
            }
        )
    }
    
    func createFile(taskId: Int?, name: String, mimeType: MimeType, folderID: String, completion: @escaping (Result<Bool, AppError>) -> Void) {
        googleService.load(
            FileItem.self,
            method: .post,
            path: "/drive/v3/files",
            token: UserStorage.googleToken,
            json: .dict([
                "name": name,
                "mimeType": mimeType.stringType,
                "parents": [folderID],
            ]),
            completion: { result in
                if let t = taskId {
                    print("protocolCreateEditFileFolder start")
                    MyAPIServic().protocolCreateEditFileFolder(
                        taskId: t,
                        fileName: name,
                        createOrEdit: 0,
                        folderOrFile: mimeType == .folder ? 0 : 1,
                        completion: { _ in }
                    )
                }
                switch result {
                case .failure(let error):
                    completion(.failure(error))
                case .success(_):
                    completion(.success(true))
                }
            }
        )
    }
    
    func deleteFile(taskId: Int?, isFolder: Bool, fileName: String, fileID: String, completion: @escaping (Result<Bool, AppError>) -> Void) {
        googleService.load(
            FileItem.self,
            method: .delete,
            path: "/drive/v3/files/\(fileID)",
            token: UserStorage.googleToken,
            completion: { result in
                if let t = taskId {
                    print("protocolCreateEditFileFolder start")
                    MyAPIServic().protocolCreateEditFileFolder(
                        taskId: t,
                        fileName: fileName,
                        createOrEdit: 2,
                        folderOrFile: isFolder ? 0 : 1,
                        completion: { _ in }
                    )
                }
                completion(.success(true))
            }
        )
    }
    
    func uploadFile(taskId: Int?, fileUrl: URL, folderID: String, completion: @escaping (Result<Bool, AppError>) -> Void) {
        let (data, boundary) = dataAndBoundaryForUploadFile(fileUrl: fileUrl, folderID: folderID)
        
        googleService.load(
            FilesResponse.self,
            method: .post,
            path: "/upload/drive/v3/files",
            token: UserStorage.googleToken,
            queryParams: [
                "uploadType": "multipart",
                "key": "AIzaSyA2XuDTRAAyBFbDwbuWq-B_WvRm8HDT2x8",
            ],
            json: .data(data),
            headers: [
                "Content-Type": "multipart/related; boundary=\(boundary)",
                "Content-Length": "\(data.count)",
            ],
            completion: { result in
                if let t = taskId {
                    print("protocolCreateEditFileFolder start")
                    MyAPIServic().protocolCreateEditFileFolder(
                        taskId: t,
                        fileName: fileUrl.lastPathComponent,
                        createOrEdit: 0,
                        folderOrFile: 1,
                        completion: { _ in }
                    )
                }
                switch result {
                case .failure(let error):
                    completion(.failure(error))
                case .success(_):
                    completion(.success(true))
                }
            }
        )
    }
    
    func updateFile(taskId: Int?, fileUrl: URL, fileID: String, completion: @escaping (Result<Bool, AppError>) -> Void) {
        let (data, boundary) = dataAndBoundaryForUploadFile(fileUrl: fileUrl)
        
        googleService.load(
            FilesResponse.self,
            method: .patch,
            path: "/upload/drive/v3/files/\(fileID)",
            token: UserStorage.googleToken,
            queryParams: [
                "uploadType": "multipart",
                "key": "AIzaSyA2XuDTRAAyBFbDwbuWq-B_WvRm8HDT2x8",
            ],
            json: .data(data),
            headers: [
                "Content-Type": "multipart/related; boundary=\(boundary)",
                "Content-Length": "\(data.count)",
            ],
            completion: { result in
                if let t = taskId {
                    print("protocolCreateEditFileFolder start")
                    MyAPIServic().protocolCreateEditFileFolder(
                        taskId: t,
                        fileName: fileUrl.lastPathComponent,
                        createOrEdit: 1,
                        folderOrFile: 1,
                        completion: { _ in }
                    )
                }
                switch result {
                case .failure(let error):
                    completion(.failure(error))
                case .success(_):
                    completion(.success(true))
                }
            }
        )
    }
    
    func donwloadFile(name: String, fileID: String, mimeType: String, completion: @escaping (Result<Bool, AppError>) -> Void) {
        googleService.downloadFile(
            name: name,
            path: "/drive/v3/files/\(fileID)",
            queryParams: ["alt": "media"],
            token: UserStorage.googleToken,
            completion: { result in
                print(result)
            }
        )
    }
    
    func givePermission(fileID: String, userEmail: String, completion: @escaping (Result<Bool, AppError>) -> Void) {
        serverService.load(
            FileItem.self,
            method: .post,
            path: "/permission",
            token: UserStorage.myToken,
            json: .dict([
                "file_id": fileID,
                "user_email": userEmail,
            ]),
            completion: { result in
                switch result {
                case .failure(let error):
                    completion(.failure(error))
                case .success(_):
                    completion(.success(true))
                }
            }
        )
    }
    
    private func dataAndBoundaryForUploadFile(fileUrl: URL, folderID: String? = nil) -> (Data, String) {
        let boundary = UUID().uuidString
        
        var mimeType: MimeType = .txt
        if let ext = fileUrl.absoluteString.split(separator: ".").last {
            mimeType = MimeType(fromExtention: String(ext)) ?? .txt
        } else {
            mimeType = .folder
        }
        
        var json: [String : Any] = [
            "name": fileUrl.lastPathComponent,
        ]
        if let folderID = folderID {
            json["parents"] = [folderID]
        }
        
        let contentOfFile = (try? Data(contentsOf: fileUrl)) ?? Data()
        
        var data = Data()
        
        data.append("\r\n--\(boundary)\r\n".data(using: .utf8)!)
        data.append("Content-Type: application/json; charset=UTF-8\r\n".data(using: .utf8)!)
        data.append("\r\n".data(using: .utf8)!)
        data.append(try! JSONSerialization.data(withJSONObject: json, options: []))
        data.append("\r\n".data(using: .utf8)!)
        
        data.append("\r\n--\(boundary)\r\n".data(using: .utf8)!)
        data.append("Content-Type: \(mimeType.stringType)\r\n\r\n".data(using: .utf8)!)
        data.append(contentOfFile)
        
        data.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        
        return (data, boundary)
    }
}
