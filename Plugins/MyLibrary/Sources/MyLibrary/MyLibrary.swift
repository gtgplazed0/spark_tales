import UIKit
import SwiftGodot
import PhotosUI

#initSwiftExtension(
    cdecl: "swift_entry_point",
    types: [MyLibrary.self]
)

@Godot
class MyLibrary: RefCounted, PHPickerViewControllerDelegate {
    #signal("Output", arguments: ["output": String.self])
    let signal = SignalWith1Argument<String>("Output")
    
    @Callable
    func pickPhoto() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first,
              let rootViewController = window.rootViewController else {
            return
        }
        var configuration = PHPickerConfiguration()
        configuration.selectionLimit = 1
        configuration.filter = .images
        
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = self
        rootViewController.present(picker, animated: true, completion: nil)
    }
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true, completion: nil)
        guard let result = results.first else {return}
        
        if result.itemProvider.hasItemConformingToTypeIdentifier(UTType.image.identifier){
            result.itemProvider.loadFileRepresentation(forTypeIdentifier: UTType.image.identifier){
                [weak self] (url, error) in
                guard let self = self, let url = url else {
                    print("failed to load image file: \(error?.localizedDescription ?? "unknown error")")
                    return
                }
                let fileManager = FileManager.default
                let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
                let destinationURL = documentsDirectory.appendingPathComponent(url.lastPathComponent)
                
                do {
                    if fileManager.fileExists(atPath: destinationURL.path){
                        try fileManager.removeItem(at: destinationURL)
                    }
                    try fileManager.copyItem(at: url, to: destinationURL)
                    debugPrint(destinationURL.path)
                    
                    DispatchQueue.main.async {
                        self.emit(signal: self.signal, destinationURL.path(percentEncoded: false))
                    }
                } catch {
                    print("error copying image file: \(error.localizedDescription)")
                }
            }
        }
    }
}
