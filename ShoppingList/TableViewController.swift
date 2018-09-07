//
//  TableViewController.swift
//  ShoppingList
//
//  Created by Usuário Convidado on 25/08/2018.
//  Copyright © 2018 BICMSystems. All rights reserved.
//

import UIKit
import Firebase
import FirebaseAuth
import FirebaseFirestore

class TableViewController: UITableViewController {

    var shoppingListCollection = "shoppingList"
    var firestoreListener: ListenerRegistration!
    
    var shoppingList: [ShoppingItem] = []
    
    lazy var firestore: Firestore = {
        
        let settings = FirestoreSettings()
        settings.areTimestampsInSnapshotsEnabled = true
        settings.isPersistenceEnabled = true
        
        let store = Firestore.firestore()
        store.settings = settings
        return store
        
    }()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let name = Auth.auth().currentUser?.displayName {
            title = name
        }
        listItems()
        
    }
    
    func listItems() {
        
        firestoreListener = firestore.collection(shoppingListCollection).whereField("author_id", isEqualTo: Auth.auth().currentUser!.uid)
            .addSnapshotListener(includeMetadataChanges: true, listener: { (snapshot, error) in
            if error != nil {
                print("Erro ao recuperar coleção: ", error!.localizedDescription)
            } else {
                
                guard let snapshot = snapshot else {
                    print("Não tem snapshot")
                    return
                }
                print("Total de Mudanças: ", snapshot.documentChanges.count)
                
                if snapshot.metadata.isFromCache || snapshot.documentChanges.count > 0 {
                    
                    self.showItems(snapshot: snapshot)
                    
                }
                
            }
        })
    }
    
    func showItems(snapshot: QuerySnapshot?) {
        
        guard let snapshot = snapshot else { return }
        
        shoppingList.removeAll()
        for document in snapshot.documents {
            
            let data = document.data()
            
            let name = (data["name"] as? String) ?? ""
            let quantity = (data["quantity"] as? Int) ?? 0
            let id = document.documentID
            
            let shoppingItem = ShoppingItem(name: name, quantity: quantity, id: id)
            shoppingList.append(shoppingItem)
        }
        tableView.reloadData()
        
    }
    
    
    @IBAction func showItemAlert(_ sender: UIBarButtonItem) {
        
        showAlert(shoppingItem: nil)
        
    }
    
    func showAlert(shoppingItem: ShoppingItem?) {
        
        let title = shoppingItem == nil ? "Adicionar" : "Editar"
        let message = shoppingItem == nil ? "adicionado" : "editado"
        let alert = UIAlertController(title: "\(title) Item", message: "Digite abaixo os dados do item a ser \(message)", preferredStyle: .alert)
        
        alert.addTextField { (textField) in
            textField.placeholder = "Nome"
            textField.text = shoppingItem?.name ?? ""
        }

        alert.addTextField { (textField) in
            textField.placeholder = "Quantidade"
            textField.keyboardType = .numberPad
            textField.text = shoppingItem?.quantity.description
        }
        
        let okAction = UIAlertAction(title: title, style: .default) { (action) in
    
            guard let name = alert.textFields?.first?.text,
                  let quantity = alert.textFields?.last?.text,
                  !name.isEmpty, !quantity.isEmpty else { return }
            
            var item = shoppingItem ?? ShoppingItem()
            item.name = name
            item.quantity = Int(quantity) ?? 0
            
            self.sendToFirestore(item)
            
        }
        
        let cancelAction = UIAlertAction(title: "Cancelar", style: .cancel, handler: nil)
        alert.addAction(okAction)
        alert.addAction(cancelAction)
        
        present(alert, animated: true, completion: nil)
        
    }
    
    func sendToFirestore(_ item: ShoppingItem) {
        
        if item.id.isEmpty {
            
            var dict = item.dict
            dict["author_id"] = Auth.auth().currentUser!.uid
            
            // Criando
            firestore.collection(shoppingListCollection).addDocument(data: dict) { (error) in
                if error == nil {
                    self.tableView.reloadData()
                } else {
                    print("Erro ao incluir Item: ", error!.localizedDescription)
                }
            }
        } else {
            // Modificando
            firestore.collection(shoppingListCollection).document(item.id).updateData(item.dict) { (error) in
                if error == nil {
                    self.tableView.reloadData()
                } else {
                    print("Erro ao atualizar Item: ", error!.localizedDescription)
                }
            }
            
        }
        
    }
    
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return shoppingList.count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)

        // Configure the cell...
        let shoppingItem = shoppingList[indexPath.row]

        cell.textLabel?.text = shoppingItem.name
        cell.detailTextLabel?.text = "\(shoppingItem.quantity)"
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let shoppingItem = shoppingList[ indexPath.row]
        showAlert(shoppingItem: shoppingItem)
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */
    
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        
        if editingStyle == .delete {
        
            let item = shoppingList[indexPath.row]
            firestore.collection(shoppingListCollection).document(item.id).delete { (error) in
                if error != nil {
                    print("Erro ao excluir item: ", error!.localizedDescription)
                }
            }
            
        }
    }
    

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    
    
    

}
