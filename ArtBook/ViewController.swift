//
//  ViewController.swift
//  ArtBook
//
//  Created by Eren on 16.08.2024.
//

import UIKit
import CoreData

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var tableView: UITableView!
    var nameArray = [String]()
    var idArray = [UUID]()
    
    var selectedPainting = ""
    var selectedPaintingId : UUID?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
        
        // Ekranın sol üst köşesinde '+' simgesi oluşturmak ve ne işe yaradığını tanımlamak için.
        navigationController?.navigationBar.topItem?.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.add, target: self, action: #selector(addButtonClicked))
        
        getData()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        NotificationCenter.default.addObserver(self, selector: #selector(getData), name: NSNotification.Name(rawValue: "newData"), object: nil) //Yeni veri girildiğinde yapılacaklar için.
    }
    
    @objc func getData() {
        
        //Remove old objects.
        nameArray.removeAll(keepingCapacity: false)
        idArray.removeAll(keepingCapacity: false)
        
        // Bu iki satır kalıp. UserDefault gibi, CoreData'ya erişebilmek için yapıyoruz.
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Paintings")
        fetchRequest.returnsObjectsAsFaults = false //hızlı olması için, cache'de okuma işlemleri ile ilgili.
        
        do {
            let results = try context.fetch(fetchRequest)
            
            if results.count > 0{
                for result in results as! [NSManagedObject]{ //sonuçları tek tek core data model objesi olarak ele almak için.
                    if let name = result.value(forKey: "name") as? String { //Painting Entity'sinde O andaki resmin adını arıyoruz.
                        self.nameArray.append(name)
                    }
                    if let id = result.value(forKey: "id") as? UUID { //Painting Entity'sinde O andaki resmin UUID'sini arıyoruz.
                        self.idArray.append(id)
                    }
                    
                    self.tableView.reloadData() //TableView güncellendiği için yeniden yüklüyoruz.
                }
            }
        }
        catch {
            print("Loading Error!")
        }
        
    }

    @objc func addButtonClicked() {
        selectedPainting = "" // resim seçilmedi.
        performSegue(withIdentifier: "toDetailVC", sender: nil)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return nameArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // Bir kalıp. TableView içine cell (satır) eklemek için bu kalıbı kullanıyoruz.
        let cell = UITableViewCell()
        cell.textLabel?.text = nameArray[indexPath.row]
        return cell
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toDetailVC" { // diğer viewcontroller'a göndermek için
            let destinationVC = segue.destination as! DetailViewController //Gidilecek viewController'ın o olduğunu biliyoruz. O ViewController'daki variablelara erişebilmek için.
            destinationVC.choosenPainting = selectedPainting
            destinationVC.choosenPaintingId = selectedPaintingId
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedPainting = nameArray[indexPath.row] //resim seçildi
        selectedPaintingId = idArray[indexPath.row] //uuid seçildi
        performSegue(withIdentifier: "toDetailVC", sender: nil)
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            
            //CoreData işlemleri
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            let context = appDelegate.persistentContainer.viewContext
            
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Paintings") //önce çağırıp sonra silmek için.
            let idString = idArray[indexPath.row].uuidString
            
            fetchRequest.predicate = NSPredicate(format: "id = %@", idString)
            fetchRequest.returnsObjectsAsFaults = false
            
            do {
                let results = try context.fetch(fetchRequest)
                
                if results.count > 0 {
                    for result in results as! [NSManagedObject] {
                        if let id = result.value(forKey: "id") as? UUID {
                            if id == idArray[indexPath.row] {
                                context.delete(result) // CoreData'dan o anki tıklanan result'ı (result burda direkt listede eklenmiş painting) siliyor.
                                nameArray.remove(at: indexPath.row)
                                idArray.remove(at: indexPath.row)
                                self.tableView.reloadData()
                                
                                do {
                                    try context.save() // Bittikten sonraki halini kaydediyoruz.
                                }
                                catch {
                                    print("Context Save Error!")
                                }
                                
                                break // sileceğim şeyi bulup sildikten sonra for loop'u bitirmek için.
                                
                            }
                        }
                    }
                }
            }
            catch {
                print("Delete Error!")
            }
            
        }
    }

}

