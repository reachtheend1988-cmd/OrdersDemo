//
//  ContentView.swift
//  OrdersDemo
//
//  Created by huanjiao qiu on 17/2/2026.
//

import SwiftUI

struct ContentView: View {
    let environment: AppEnvironment

    var body: some View {
        AppRootView(environment: environment)
    }
}

#if DEBUG
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(environment: AppEnvironment(ordersRepository: MockOrdersRepository.demo(sleeper: .immediate)))
    }
}
#endif
