//
//  File.swift
//  Continuum
//
//  Created by John Tate on 9/25/18.
//  Copyright © 2018 John Tate. All rights reserved.
//

import UIKit
import CloudKit

extension PostController {
    static let PostsChangedNotification = Notification.Name("PostsChangedNotification")
    static let PostCommentsChangedNotification = Notification.Name("CommentsChangedNotification")
}

class PostController {
    
    // shared instance or singleton
    static let shared = PostController()
    
    let publicDB = CKContainer.default().publicCloudDatabase

    // source of truth
    var posts: [Post] = [] {
        didSet {
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: PostController.PostsChangedNotification, object: self)
            }
        }
    }
    
    // MARK: - CloudKit Availability
    
    func checkAccountStatus(completion: @escaping (_ isLoggedIn: Bool) -> Void) {
        
        CKContainer.default().accountStatus { [weak self] (status, error) in
         
            if let error = error {
                print("Error checking account status \(error) \(error.localizedDescription)")
                completion(false)
                return
            } else {
                let errorText = "Sign into iCloud in Settings"
                // switch based on status; have to be exhaustive, i.e., include all 4 settings of CKAccountStatus enum: https://developer.apple.com/documentation/cloudkit/ckaccountstatus
                switch status {
                case .available:
                    completion(true)
                case .noAccount:
                    self?.presentErrorAlert(errorTitle: errorText, errorMessage: "No iCloud account found")
                    completion(false)
                case .couldNotDetermine:
                    self?.presentErrorAlert(errorTitle: errorText, errorMessage: "Error with iCloud account status; could not determine account status")
                    completion(false)
                case .restricted:
                    self?.presentErrorAlert(errorTitle: errorText, errorMessage: "Restricted iCloud account")
                    completion(false)
                }
            }
        }
    }
    
    func presentErrorAlert(errorTitle: String, errorMessage: String) {
        
        DispatchQueue.main.async {
            if let appDelegate = UIApplication.shared.delegate,
                let appWindow = appDelegate.window!,
                let rootViewController = appWindow.rootViewController {
                rootViewController.presentAlertControllerWith(title: errorTitle, message: errorMessage)
            }
        }
    }
    
    
    
    
    // CRUD functions
    
    // MARK: - Create
    func addComment(text: String, to post: Post, completion: @escaping (Comment?) -> Void) {
        
        let newComment = Comment(text: text, post: post)
        post.comments.append(newComment)
        
        publicDB.save(CKRecord(newComment)) { (_, error) in
            
            if let error = error {
                print("Error saving comment \(error) \(error.localizedDescription)")
                completion(nil)
                return
            }
            completion(newComment)
        }
    }
    
    func createPostWith(image: UIImage, caption: String, completion: @escaping (Post?) -> Void) {
        
        let newPost = Post(photo: image, caption: caption)
        self.posts.append(newPost)
        
        publicDB.save(CKRecord(newPost)) { (_, error) in
            
            if let error = error {
                print("Error saving post record \(error) \(error.localizedDescription)")
                completion(nil)
                return
            }
            completion(newPost)
        }
    }
 
    // MARK: - Fetch
    
    func fetchPostsFromCloudKit(completion: @escaping ([Post]?) -> Void) {
        
        // here all posts are fetched, which is not very efficient
        let fetchAllPostsPredicate = NSPredicate(value: true)
        let fetchPostsQuery = CKQuery(recordType: "Post", predicate: fetchAllPostsPredicate)
        
        publicDB.perform(fetchPostsQuery, inZoneWith: nil) { (records, error) in
            
            if let error = error {
                print("Error fetching posts from CloudKit \(#function) \(error) \(error.localizedDescription)")
                completion(nil)
                return
            }
            guard let records = records else { completion(nil); return }
            // convert the records into an array of posts using the failable initializer
            let fetchedPosts = records.compactMap{ Post(record: $0) }
            self.posts = fetchedPosts
            completion(fetchedPosts)
        }
    }
    
    func fetchComments(for post: Post, completion: @escaping (Bool) -> Void) {
        
        let postReference = post.recordID
        // here fetch the posts
        let fetchPostsPredicate = NSPredicate(format: "postReference == %@", postReference)
        let commentIDs = post.comments.compactMap({ $0.recordID })
        // here fetch the comments
        let fetchCommentsPredicate = NSPredicate(format: "NOT(recordID IN %@)", commentIDs)
        // create a compound predicate
        let compoundPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [fetchPostsPredicate, fetchCommentsPredicate])
        let fetchCommentsQuery = CKQuery(recordType: "Comment", predicate: compoundPredicate)
        
        publicDB.perform(fetchCommentsQuery, inZoneWith: nil) { (records, error) in
            
            if let error = error {
                print("Error fetching comments from CloudKit \(#function) \(error) \(error.localizedDescription)")
                completion(false)
                return
            }
            
            guard let records = records else { completion(false); return }
              // convert the records into an array of comments using the failable initializer
            let fetchedComments = records.compactMap{ Comment(record: $0)}
            post.comments.append(contentsOf: fetchedComments)
            completion(true)
        }
    }
}
