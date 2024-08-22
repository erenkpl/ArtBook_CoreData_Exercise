//
//  DetailViewController.swift
//  ArtBook
//
//  Created by Eren on 16.08.2024.
//

import UIKit
import CoreData

class DetailViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var nameText: UITextField!
    @IBOutlet weak var artistText: UITextField!
    @IBOutlet weak var yearText: UITextField!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var artistLabel: UILabel!
    @IBOutlet weak var yearLabel: UILabel!
    
    @IBOutlet weak var saveButtonOutlet: UIButton! //Buton üzerinde gösterip gizleyebilmek gibi hakimiyetlerimizin olması için outlet olarak tanımladık.
    
    var choosenPainting = ""
    var choosenPaintingId : UUID?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if choosenPainting != "" {
            
            hideLabel(isTrue: true)
            
            // Core Data
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            let context = appDelegate.persistentContainer.viewContext
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Paintings") //Painting Entity'sine erişebilmek için.
            let idString = choosenPaintingId?.uuidString //Seçilen resmin UUID'sini string olarak kaydediyoruz.
            
            fetchRequest.predicate = NSPredicate(format: "id = %@", idString!) //seçilen resimdeki uuid ile aynı uuid olanı buluyoruz.
            fetchRequest.returnsObjectsAsFaults = false
            
            do {
                let results = try context.fetch(fetchRequest)
                
                if results.count > 0{
                    // Aynı uuid'ye girilmiş olan özellikleri ekranda göstermek için eşliyoruz.
                    for result in results as! [NSManagedObject] {
                        
                        if let name = result.value(forKey: "name") as? String{
                            nameLabel.text = name
                        }
                        
                        if let artist = result.value(forKey: "artist") as? String{
                            artistLabel.text = artist
                        }
                        
                        if let year = result.value(forKey: "year") as? Int {
                            yearLabel.text = String(year)
                        }
                        
                        if let imageData = result.value(forKey: "image") as? Data{
                            let image = UIImage(data: imageData)
                            imageView.image = image
                        }
                        
                    }
                }
            }
            catch{
                print("Information Loading Error!")
            }
            
        }
        else{
            hideLabel(isTrue: false)
            saveButtonOutlet.isEnabled = false
        }
        
        //Recognizers
        
        let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(hideKey))
        view.addGestureRecognizer(gestureRecognizer)
        
        imageView.isUserInteractionEnabled = true
        let imageTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(selectImage))
        imageView.addGestureRecognizer(imageTapRecognizer)
        
    }
    
    @IBAction func saveButton(_ sender: Any) {
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate //appdelegate dosyasını kullanmak için
        let context = appDelegate.persistentContainer.viewContext
        
        let newPainting = NSEntityDescription.insertNewObject(forEntityName: "Paintings", into: context) //core data kütüphanesi, soldaki ArtBook'ta Painting entitysine eklemek için.
        
        //Atributes
        newPainting.setValue(nameText.text, forKey: "name")
        newPainting.setValue(artistText.text, forKey: "artist")
        
        if let year = Int(yearText.text!){
            newPainting.setValue(year, forKey: "year")
        }
        
        newPainting.setValue(UUID(), forKey: "id") //her seferinde uuid random bir id oluşturacak.
        
        let data = imageView.image!.jpegData(compressionQuality: 0.5)
        
        newPainting.setValue(data, forKey: "image")
        
        do {
            try context.save()
        }
        catch {
            print("Save Error!")
        }
        
        NotificationCenter.default.post(name: NSNotification.Name("newData"), object: nil) //Yeni veri girildiğinde, sistemi uyarmak için.
        self.navigationController?.popViewController(animated: true)
        
    }
    
    @objc func hideKey(){
        view.endEditing(true)
    }
    
    @objc func selectImage(){
        
        // Galeriden fotoğraf seçtirmek için.
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = .photoLibrary
        picker.allowsEditing = true
        present(picker, animated: true)
        
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        //Seçilen image'i kaydetmek için.
        imageView.image = info[.originalImage] as? UIImage
        saveButtonOutlet.isEnabled = true
        self.dismiss(animated: true)
    }
    
    func hideLabel(isTrue : Bool){
        // Hiding and showing labels when it needed.
        nameText.isHidden = isTrue
        artistText.isHidden = isTrue
        yearText.isHidden = isTrue
        saveButtonOutlet.isHidden = isTrue
        nameLabel.isHidden = !isTrue
        artistLabel.isHidden = !isTrue
        yearLabel.isHidden = !isTrue
    }
    
}
