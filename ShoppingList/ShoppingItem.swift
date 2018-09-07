//
//  ShoppingItem.swift
//  ShoppingList
//
//  Created by Usuário Convidado on 25/08/2018.
//  Copyright © 2018 BICMSystems. All rights reserved.
//

import Foundation

struct ShoppingItem {
    
    var name: String = ""
    
    var quantity: Int = 0
    
    var id: String = ""
    
    var dict: [String: Any]{
        
        return ["name": name, "quantity": quantity]
        
    }
    
}

