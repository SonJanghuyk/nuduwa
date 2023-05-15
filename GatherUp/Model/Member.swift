//
//  Members.swift
//  GatherUp
//
//  Created by DaelimCI00007 on 2023/04/17.
//

import SwiftUI
import Firebase
import FirebaseFirestoreSwift

struct Member: Identifiable,Codable,Equatable, Hashable, FirestoreConvertible{
    @DocumentID var id: String?
    
    let memberUID: String
    var memberName: String?
    var memberImage: URL?
    var joinDate: Timestamp

//    init(id: String? = nil, memberUID: String, joinDate: Timestamp) {
//
//    }
    // Firestore에서 가져올 필드 - guard문 값이 하나라도 없으면 nil 반환
    init?(data: [String: Any], id: String) {
        guard let memberUID = data["memberUID"] as? String,
              let joinDate = data["joinDate"] as? Timestamp
        else { return nil }
        
        self.id = id
        self.memberUID = memberUID
        self.joinDate = joinDate
    }
    
    // Firestore에 저장할 필드
    var firestoreData: [String: Any] {
        return [
            "memberUID": memberUID,
            "joinDate": FieldValue.serverTimestamp()
        ]
    }
    
    // 객체 안만들고 Firestore 바로 저장하기
    static func member(_ memberUID: String) -> [String: Any] {
        return [
            "memberUID": memberUID,
            "joinDate": FieldValue.serverTimestamp()
        ]
    }
}



