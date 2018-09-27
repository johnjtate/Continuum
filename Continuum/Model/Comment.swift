//
//  Comment.swift
//  Continuum
//
//  Created by John Tate on 9/25/18.
//  Copyright © 2018 John Tate. All rights reserved.
//

import Foundation
import CloudKit

class Comment {
    
    let typeKey = "Comment"
    // Add fileprivate strings for your keys to keep your code safe.
    fileprivate let textKey = "text"
    fileprivate let timestampKey = "timestamp"
    fileprivate let postReferenceKey = "postReference"
    
    // Add a recordID property that is equal to a 'CKRecord.ID' with a default value of a uuidString.
    var recordID = CKRecord.ID(recordName: UUID().uuidString)
    var text: String
    var timestamp: Date
    weak var post: Post?
    
    init(text: String, timestamp: Date = Date(), post: Post?) {
        self.text = text
        self.timestamp = timestamp
        self.post = post
    }
    
    convenience required init?(record: CKRecord) {
        guard let text = record["text"] as? String,
            let timestamp = record.creationDate else { return nil }
        self.init(text: text, timestamp: timestamp, post: nil)
        self.recordID = record.recordID
    }
}

// 2. Add an extention on CKRecord that will set create the CKRecord.ID of a 'Comment' object and set each value. It will need the required convenience initializer init?(record: CKRecord) and set each property.
extension CKRecord {
    convenience init(_ comment: Comment) {
        guard let post = comment.post else {
            fatalError("Comment does not have a Post relationship!")
        }
        self.init(recordType: comment.typeKey, recordID: comment.recordID)
        self.setValue(comment.text, forKey: comment.textKey)
        self.setValue(comment.timestamp, forKey: comment.timestampKey)
        self.setValue(CKRecord.Reference(recordID: post.recordID, action: .deleteSelf), forKey: comment.postReferenceKey)
    }
}

extension Comment: SearchableRecord {
    
    func matches(searchTerm: String) -> Bool {
        // both the user input and the model object are made lowercased, which allows us to use that Strings conform to Equatable
        return self.text.lowercased().contains(searchTerm.lowercased())
    }
}
