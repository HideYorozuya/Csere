//
//  ChatViewController.swift
//  Csere
//
//  Created by Athul Sasikumar on 05/09/1943 Saka.
//

import UIKit
import MessageKit
import InputBarAccessoryView
import RealmSwift

struct Message: MessageType {
    public var sender: SenderType
    public var messageId: String
    public var sentDate: Date
    public var kind: MessageKind
}

extension MessageKind {
    var messageKindString: String {
        switch self {
            
        case .text(_):
            return "text"
        case .attributedText(_):
            return "attributed_text"
        case .photo(_):
            return "photo"
        case .video(_):
            return "video"
        case .location(_):
            return "location"
        case .emoji(_):
            return "emoji"
        case .audio(_):
            return "audio"
        case .contact(_):
            return "contact"
        case .linkPreview(_):
            return "linkPreview"
        case .custom(_):
            return "custom"
        }
    }
}

struct Sender: SenderType {
    public var photoURL: String
    public var senderId: String
    public var displayName: String
}

class ChatViewController: MessagesViewController {
    
    public static let dateFormatter: DateFormatter = {
        let formattre = DateFormatter()
        formattre.dateStyle = .medium
        formattre.timeStyle = .long
        formattre.locale = .current
        return formattre
    }()
    
    public let otherUserEmail: String
    private let conversationId: String?
    public var isNewConversation = false
   
    private var messages = [Message]()
    
    private var selfSender: Sender? {
        guard let email = UserDefaults.standard.value(forKey: "email") as? String else {
            return nil
        }
        
        return Sender(photoURL: "",
               senderId: email,
               displayName: "Joe Smith")
    }
    
    init(with email: String, id: String?) {
        self.conversationId = id
        self.otherUserEmail = email
        super.init(nibName: nil, bundle: nil)
        if let conversationId = conversationId {
            listenForMessages(id: conversationId)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
       view.backgroundColor = .red
        
        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self
        messageInputBar.delegate = self
        }
    
    private func listenForMessages(id: String) {
        DatabaseManager.shared.getAllMessagesForConversation(with: id, completion: { [weak self] result in
            switch result {
            case .success(let messages):
                guard !messages.isEmpty else {
                    return
                }
                self?.messages = messages
                print("error")
                DispatchQueue.main.sync {
                    self?.messagesCollectionView.reloadData()
                }
            case .failure(let error):
                print("failed to get messages: \(error)")
            }
        })
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        messageInputBar.inputTextView.becomeFirstResponder()
    }
    
}

extension ChatViewController: InputBarAccessoryViewDelegate {
    
    func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text: String) {
        guard !text.replacingOccurrences(of: " ", with: "").isEmpty,
        let selfSender = self.selfSender,
        let messageId = createMessageId() else {
            return
        }
        
        print("Sending: \(text)")
        
        // Send Message
        if isNewConversation {
            // Create convo in database
            let mmessage = Message(sender: selfSender,
                                   messageId: messageId,
                                   sentDate: Date(),
                                   kind: .text(text))
            DatabaseManager.shared.createNewconversation(with: otherUserEmail, name: self.title ?? "User", firstMessage: mmessage, completion: { success in
                if success {
                    print("message sent")
                }
                else {
                    print("failed to send")
                }
            })
        }
        else {
            // append to existing conversation data
            
        }
    }
    
    private func createMessageId() -> String? {
        // date, otherUserEmail, senderEmail, randomInt
       guard let currentUserEmail = UserDefaults.standard.value(forKey: "email") as? String else {
            return nil
        }
        
        let safeCurrentEmail = DatabaseManager.safeEmail(emailAddress: currentUserEmail)
        
        let dateString = Self.dateFormatter.string(from: Date())
        let newIdentifier = "\(otherUserEmail)_\(safeCurrentEmail)_\(dateString)"
        print("created message id: \(newIdentifier)")
        return newIdentifier
    }
    
}


extension ChatViewController: MessagesDataSource, MessagesLayoutDelegate, MessagesDisplayDelegate {
    func currentSender() -> SenderType {
        if let sender = selfSender {
            return sender
        }
        
        fatalError("Self Sender is nil, email should be cached")
        
    }
    
    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageType {
        return messages[indexPath.section]
    }
    
    func numberOfSections(in messagesCollectionView: MessagesCollectionView) -> Int {
        return messages.count
    }
    
    }
