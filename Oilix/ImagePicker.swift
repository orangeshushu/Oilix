//
//  ImagePicker.swift
//  Oilix
//
//  Created by Guo, Congyu on 12/6/21.
//


import SwiftUI
import PhotosUI
/*
 import ImageIO
 
 struct PhotoPicker: UIViewControllerRepresentable{
 @Binding var pickedImage: UIImage
 func makeUIViewController(context: Context) -> some UIViewController {
 let picker=UIImagePickerController()
 picker.delegate=context.coordinator
 picker.allowsEditing=true
 return picker
 }
 func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {}
 
 func makeCoordinator() -> Coordinator {
 return Coordinator(photoPicker: self)
 }
 
 final class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate{
 let photoPicker: PhotoPicker
 init(photoPicker: PhotoPicker){
 self.photoPicker=photoPicker
 }
 func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
 if let image = info[.editedImage] as? UIImage{
 guard let data=image.jpegData(compressionQuality: 1), let jpegImage=UIImage(data: data) else{
 return
 }
 photoPicker.pickedImage=jpegImage
 
 let imageURL = info[UIImagePickerController.InfoKey.referenceURL]
 let imageData = image.pngData()
 let cgis = CGImageSourceCreateWithData(imageData! as CFData, nil)!
 let cgis2 = CGImageSourceCreateWithURL(imageURL as! CFURL, nil)!
 var tm = CGImageSourceCopyPropertiesAtIndex(cgis2, 0, nil) as? [AnyHashable: Any]
 print(tm)
 }else{
 
 }
 picker.dismiss(animated: true)
 }
 }
 }
 */
struct ImagePicker : UIViewControllerRepresentable{
    
    func makeCoordinator() -> Coordinator {
        return ImagePicker.Coordinator(parent1: self)
    }
    
    /*
    @Binding var images : [UIImage]
    @Binding var locations : [String]
    @Binding var notes : [String]
    @Binding var times : [Date]
     */
    @Binding var picker : Bool
    //@Binding var attr : String
    
    @StateObject var samples : WaterSampleViewModel
    
    func makeUIViewController(context: Context) -> some PHPickerViewController {
        let photoLibrary = PHPhotoLibrary.shared()
        var config=PHPickerConfiguration(photoLibrary: photoLibrary)
        config.filter = .images
        config.selectionLimit=0
        let picker=PHPickerViewController(configuration: config)
        picker.delegate=context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {
        
    }
    
    class Coordinator: NSObject, PHPickerViewControllerDelegate{
        var parent : ImagePicker
        init(parent1: ImagePicker){
            parent=parent1
        }
        func picker(_ picker: PHPickerViewController, didFinishPicking results:[PHPickerResult]){
            
            print(results.count)
            
            
            
            //print(parent.picker)
            parent.picker.toggle()
        
            //print(parent.picker)
            
            for img in results{
                if img.itemProvider.canLoadObject(ofClass: UIImage.self){
                    img.itemProvider.loadObject(ofClass: UIImage.self) { (image, err) in
                        guard let image1=image else{
                            print(err)
                            return
                        }
                        
                        if let assetId = img.assetIdentifier {
                            let assetResults = PHAsset.fetchAssets(withLocalIdentifiers: [assetId], options: nil)

                            //print("resultcount:",assetResults.count)
                            print("date:", assetResults.firstObject?.creationDate ?? "No date")
                            //print(assetResults.firstObject?.location?.coordinate ?? "No location")
                            //let fo = assetResults.firstObject!//may found nil if not allowed for access photo
                            guard let fo = assetResults.firstObject else{
                                print("may not be allowed to access photo")
                                return
                            }
                            let cr = fo.creationDate ?? Date.now
                            //self.parent.times.append(cr)
                            var teststring = ""
                            if let location = fo.location?.coordinate{
                                teststring = teststring +  String(location.latitude) + "," + String(location.longitude)
                                
                            }
                            else{
                                teststring += "0,0"//used to be "no location, "
                            }
                            //let dateFormatter = DateFormatter()
                            //dateFormatter.dateFormat = "MM/dd/y HH:mm"
                            //teststring = teststring + " " + dateFormatter.string(from: cr)
                            //self.parent.attr = teststring
//                            if let coor = assetResults.firstObjects.location?.coordinate {
//                                parent.attr = String(coor)
//                            }else{
//
//                            }
                            //print(assetResults.firstObject)
                            //print(assetResults.firstObject?.mediaType.rawValue)
                            //print(assetResults.firstObject?.sourceType.rawValue)
                            //print(assetResults.firstObject?.sourceType.
                            //let o=assetResults[
                            //self.parent.locations.append(teststring)
                            print(teststring)
                            //self.parent.notes.append("\(Int.random(in: 1...100))")
                            self.parent.samples.add(image: image1 as! UIImage, location: teststring, times: cr)
                          }
                        else{
                            print(img.assetIdentifier)
                        }
 
                        //let identifiers=results.compactMap(\.assetIdentifier)
                        //let fetchResult=PHAsset.fetchAssets(withLocalIdentifiers: identifiers, options: nil)
                        //print(identifiers.count)
                        //print(identifiers)
                        //print(results)
                        //print(fetchResult)
                        
                        //self.parent.images.append(image1 as! UIImage)
                    }
                }
            }
        }
    }
}
