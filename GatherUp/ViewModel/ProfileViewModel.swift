//
//  ProfileViewModel.swift
//  GatherUp
//
//  Created by DaelimCI00007 on 2023/04/05.
//

import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseFirestore
import GoogleSignIn
import _PhotosUI_SwiftUI

class ProfileViewModel: FirebaseViewModel {
    
    @Published var userProfilePicData: Data?
    
    // MARK: Logging User Out
    func logOutUser() {
        Task{
            do{
                try Auth.auth().signOut()
                GIDSignIn.sharedInstance.signOut()
            }catch{
                await handleError(error)
            }
        }
    }
    
    // MARK: Deleting User Entire Account
    func deleteAccount() {
        isLoading = true
        Task{
            do{
                guard let currentUID = currentUID else{return}
                // Step 1: First Deleting Profile Image From Storage
                let reference = Storage.storage().reference().child(strProfile_Images).child(currentUID)
                try await reference.delete()
                // Step 2 : Deleting Firestore User Document
                try await Firestore.firestore().collection(strUsers).document(currentUID).delete()
                // Final Step: Deleting Auth Account and Setting Log Status to False
                try await Auth.auth().currentUser?.delete()
                isLoading = false
            } catch {
                await handleError(error)
            }
        }
    }
    
    func editUser(userName: String?, userImage: PhotosPickerItem?){
        print("updateUser")
        isLoading = true
        var isAnotherLoading: [String:Bool]= [:]
        func check(){
            var isAnyLoading = false
            for loading in isAnotherLoading.values {
                if loading {
                    isAnyLoading = true
                }
            }
            if !isAnyLoading {
                self.isLoading = false
            }
        }
        Task{
            do{
                let changeRequest = Auth.auth().currentUser?.createProfileChangeRequest()
                guard let currentUID = currentUID else{return}
                
                if let userName = userName {
                    isAnotherLoading["userName"] = true
                    try await db.collection(strUsers).document(currentUID).updateData(["userName": userName])
                    changeRequest?.displayName = userName
                    changeRequest?.commitChanges()
                    isAnotherLoading["userName"] = false
                    check()
                    print("userName 수정")
                }
                if let userImage = userImage {
                    isAnotherLoading["userImage"] = true
                    let maxFileSize: Int = 100_000 // 최대 파일 크기 (예: 0.1MB)
                    var compressionQuality: CGFloat = 1.0 // 초기 압축 품질

                    let image = userImage.image
                    var jpegImage: UIImage?
                    var imageData: Data?

                    if let uiImage = UIImage(data: image) {
                        jpegImage = uiImage
                    } else if let pngData = UIImage(data: image)?.pngData() {
                        if let uiImage = UIImage(data: pngData) {
                            jpegImage = uiImage
                        }
                    } else {
                        isAnotherLoading["userImage"] = false
                        check()
                        return
                    }

                    if let jpegData = jpegImage?.jpegData(compressionQuality: compressionQuality), jpegData.count > maxFileSize {
                        imageData = jpegData
                        while imageData.count > maxFileSize && compressionQuality > 0.1 {
                            compressionQuality -= 0.1
                            imageData = uiImage.jpegData(compressionQuality: compressionQuality) ?? Data()
                        }
                    } else {
                        isAnotherLoading["userImage"] = false
                        check()
                        return
                    }
                    
                    // Firebase Storage에 이미지 업로드를 위해 해당 이미지 데이터를 사용합니다.
                    if let imageData = imageData {
                        let storageRef = Storage.storage().reference().child("Profile_Images").child(currentUID)

                        try await storageRef.putData(imageData)
                        let downloadURL = try await storageRef.downloadURL()
                        
                        try await db.collection(strUsers).document(currentUID).updateData(["userImage": downloadURL.absoluteString])
                        isAnotherLoading["userImage"] = false
                        check()
                    } else {
                        isAnotherLoading["userImage"] = false
                        check()
                        return
                    }
                }
            }catch{
                await handleError(error)
            }
        }
    }


                    // guard let imageData = try await userImage.loadTransferable(type: Data.self) else{
                    //     print("에러 imageData")
                    //     return
                    // }

//    func imageChaged(photoItem: PhotosPickerItem) {
//        print("imageChaged")
//        Task{
//            do{
//                guard let imageData = try await photoItem.loadTransferable(type: Data.self) else{
//                    print("에러 imageData")
//                    return
//                }
//                editUser(userImage: imageData)
//            }catch{
//                await handleError(error)
//            }
//        }
//    }
}
