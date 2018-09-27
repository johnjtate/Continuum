//
//  Post.swift
//  Continuum
//
//  Created by John Tate on 9/25/18.
//  Copyright © 2018 John Tate. All rights reserved.
//

import UIKit
import CloudKit

class Post {
    
    let recordTypeKey = "Post"
    // Add fileprivate strings for your keys to keep your code safe.
    fileprivate let captionKey = "caption"
    fileprivate let timestampKey = "timestamp"
    fileprivate let photoDataKey = "photoData"

    // 2. Add a recordID property that is equal to a 'CKRecord.ID' with a default value of a uuidString.
    var recordID = CKRecord.ID(recordName: UUID().uuidString)
    var photoData: Data?
    var caption: String
    var timestamp: Date
    var comments: [Comment] {
        didSet {
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: PostController.PostCommentsChangedNotification, object: self)
            }
        }
    }
    var tempURL: URL?
    
    init(photo: UIImage, caption: String, timestamp: Date = Date(), comments: [Comment] = []) {
        self.caption = caption
        self.timestamp = timestamp
        self.comments = comments
        self.photo = photo
    }
    
    var photo: UIImage? {
        get {
            guard let photoData = photoData else { return nil }
            return UIImage(data: photoData)
        }
        set {
            photoData = newValue?.jpegData(compressionQuality: 0.6)
        }
    }
    
    // 3.1 Save the image temporarily to disk
    // 3.2 Create the CKAsset
    var imageAsset: CKAsset? {
        get {
            let tempDirectory = NSTemporaryDirectory()
            let tempDirectoryURL = URL(fileURLWithPath: tempDirectory)
            let fileURL = tempDirectoryURL.appendingPathComponent(UUID().uuidString).appendingPathExtension("jpg")
            self.tempURL = fileURL
            do {
                try photoData?.write(to: fileURL)
            } catch let error {
                print("Error writing to temp url \(error) \(error.localizedDescription)")
            }
            return CKAsset(fileURL: fileURL)
        }
    }
    
    // 3.3 Remove the temporary file
    deinit {
        if let url = tempURL {
            do {
                try FileManager.default.removeItem(at: url)
            } catch let error {
                print("Error deleting temp file, or may cause memory leak: \(error)")
            }
        }
    }

    init?(record: CKRecord) {
        guard let caption = record[captionKey] as? String,
            let timestamp = record.creationDate,
            let imageAsset = record[photoDataKey] as? CKAsset else { return nil }
        
        guard let photoData = try? Data(contentsOf: imageAsset.fileURL) else { return nil}
        
        self.caption = caption
        self.timestamp = timestamp
        self.photoData = photoData
        self.comments = []
        self.recordID = record.recordID
    }
}

// 4. Add an extension on CKRecord that will create the CKRecord.ID of a 'Post' object and set each value.  It will need the required convenience initializer init?(record: CKRecord).
extension CKRecord {
    convenience init(_ post: Post) {
        let recordID = post.recordID
        self.init(recordType: post.recordTypeKey, recordID: recordID)
        self.setValue(post.caption, forKey: post.captionKey)
        self.setValue(post.timestamp, forKey: post.timestampKey)
        self.setValue(post.imageAsset, forKey: post.photoDataKey)
    }
}

extension Post: SearchableRecord {
    
    func matches(searchTerm: String) -> Bool {
        
        // search the caption
        if caption.lowercased().contains(searchTerm.lowercased()) {
            return true
        }
        
        // search the comments
        for comment in self.comments {
            if comment.matches(searchTerm: searchTerm) {
                return true
            }
        }
        
        return false
    }
}
