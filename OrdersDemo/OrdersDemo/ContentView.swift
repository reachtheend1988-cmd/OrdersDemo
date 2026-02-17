//
//  ContentView.swift
//  OrdersDemo
//
//  Created by huanjiao qiu on 17/2/2026.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        AppRootView()
    }
}

#if DEBUG
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environment(\.ordersAppEnvironment, OrdersAppEnvironment(ordersRepository: MockOrdersRepository.demo(requestDelay: .immediate)))
    }
}
#endif
