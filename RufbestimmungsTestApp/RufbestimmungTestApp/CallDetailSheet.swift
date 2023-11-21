//
//  CallDetailSheet.swift
//  RufbestimmungTestApp
//
//  Created by Volker Runkel on 09.11.23.
//

import SwiftUI
import Combine

struct CallDetailSheet: View {
    
    @State var callParameters: Dictionary<String, Float>
    @State var callMeasurements: CallMeasurements
    @State var selectedKey: String?
    
    @State var allValues: Bool = false
    var filterList: Array<String> = ["Fknee", "Fmk", "Flastms" , "Fmed", "Fmidf", "Fmidt", "FMod", "FRmin", "Rknee", "Rmk", "Rlastms", "Rmidt"]
    
    let actionPublisher = PassthroughSubject<CallDetailView.Action, Never>()
    
    var body: some View {
        HStack {
            Toggle("Show all values", isOn: $allValues)
            Button("Save image") {
                actionPublisher.send(.saveImage)
            }
        }
            .padding()
        VStack(alignment: .center) {
            CallDetailView(actionPublisher: actionPublisher, callData: callMeasurements, callParameters: callParameters, selectedKey: $selectedKey)
                .frame(width: 300, height: 300)
                .fixedSize()
            List(selection: $selectedKey) {
                if allValues {
                    ForEach(callParameters.sorted(by: {$0.key.lowercased().compare($1.key.lowercased(), options: String.CompareOptions.numeric) == .orderedAscending}), id: \.key) { key, value in
                        HStack {
                            Text(key)
                            Spacer()
                            Text("\(value, specifier: "%0.2f")")
                        }
                    }
                }
                else {
                    ForEach(filterList, id: \.self) { key in
                        HStack {
                            Text(key)
                            Spacer()
                            Text("\(callParameters[key]!, specifier: "%0.2f")")
                        }
                    }
                }
            }
        }
        .padding()
        /*.onChange(of: selectedKey) {
        }*/
        // view with call
        // list with call params
    }
}

struct CallDetailView: NSViewRepresentable {
    
    enum Action {
            case saveImage
        }
    
    let actionPublisher: any Publisher<Action, Never>
    
    @State var callData: CallMeasurements?
    @State var callParameters: Dictionary<String, Float>?
    @Binding var selectedKey: String?
    
    func makeNSView(context: Context) -> SingleCallView {
        let callPreview = SingleCallView()
        callPreview.callData = callData
        callPreview.callParameters = callParameters
        callPreview.setupView()
        
        context.coordinator.actionSubscriber = actionPublisher.sink { action in
                    switch action {
                    case .saveImage:
                        // call the required methods for setting current location
                        callPreview.saveImage()
                    }
                }
        
        return callPreview
    }
    
    func updateNSView(_ nsView: SingleCallView, context: Context) {
        nsView.selectedKey = selectedKey
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator: NSObject {
        var actionSubscriber: (any Cancellable)?
    }
    
}
