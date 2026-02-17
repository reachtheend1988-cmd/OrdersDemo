//
//  OrdersDemoApp.swift
//  OrdersDemo
//
//  Created by huanjiao qiu on 17/2/2026.
//

import SwiftUI

@main
struct OrdersDemoApp: App {
    var body: some Scene {
        WindowGroup {
            let environment = AppEnvironment(ordersRepository: MockOrdersRepository.demo())
            ContentView(environment: environment)
        }
    }
}
