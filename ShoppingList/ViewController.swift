//
//  ViewController.swift
//  ShoppingList
//
//  Created by Usuário Convidado on 25/08/2018.
//  Copyright © 2018 BICMSystems. All rights reserved.
//

import UIKit
import Firebase
import FirebaseAuth


class ViewController: UIViewController {

    @IBOutlet weak var tfEmail: UITextField!
    @IBOutlet weak var tfPassword: UITextField!
    @IBOutlet weak var tfName: UITextField!
    
    var handle: AuthStateDidChangeListenerHandle?
    var user: User?
    
    
    
    @IBAction func login(_ sender: UIButton) {
        
        if let handle = handle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
        
        Auth.auth().signIn(withEmail: tfEmail.text!, password: tfPassword.text!) { (result, error) in
            if error == nil {
                
                print("Login bem sucedido. Ir para próxima tela...")
                self.showMainScreen(user: result?.user)
                
            } else {
                
                print("Erro ao realizar login: ", error!.localizedDescription)
                
            }
        }
        
    }
    
    
    @IBAction func signup(_ sender: UIButton) {
        
        if let handle = handle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
        
        Auth.auth().createUser(withEmail: tfEmail.text!, password: tfPassword.text!) { (result, error) in
            
            if error == nil {
                
                self.performUserChange(user: result?.user)
                
            } else {
                print("Erro ao criar usuário: ", error!.localizedDescription)
            }
            
        }
        
    }
    
    func performUserChange(user: User?) {
        
        if tfName.text!.isEmpty {
            // passar para a próxima tela
            self.showMainScreen(user: user)
            return
        }
        
        let changeRequest = user?.createProfileChangeRequest()
        changeRequest?.displayName = tfName.text!
        changeRequest?.commitChanges(completion: { (error) in
            if error != nil {
                print ("Erro ao alterar nome do usuário: ", error!.localizedDescription)
            } else {
                
                // passar para a próxima tela
                self.showMainScreen(user: user)
            }
        })
        
    }
    
    func showMainScreen(user: User?, animated: Bool = true) {
        
        guard let user = user else { return }
        self.user = user
        user.getIDTokenForcingRefresh(false) { (token, error) in
            print("Token do usuário: ", token ?? "Sem token");
        }
        
        guard let vc = self.storyboard?.instantiateViewController(withIdentifier: "TableViewController") as? TableViewController else { return }
        
        self.navigationController?.pushViewController(vc, animated: animated)
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // faz a autenticação no firebase
        handle = Auth.auth().addStateDidChangeListener({ (auth, user) in
            
            print("Usuário logado: ", user?.displayName ?? "Sem nome" )
            
            if let user = user {
                print("Email: ", user.email ?? "Sem email")
                print("Nome: ", user.displayName ?? "Sem nome")
                print("ID: ", user.uid)
                print("Entrar na tela de lista de compras")
                self.showMainScreen(user: user)
            }
            
        })
        
        
    }


}

