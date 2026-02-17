

import SwiftUI
import Combine

class OnbordingViewModel: ObservableObject {
    @Published var currentPage: Int = 0
    @Published var textForButton: String  = "Start"
    @Published var shuoldRequestReview: Bool = false
    @Published var showTermOfUseAndPrivacy: Bool = false
    @Published var bgTitel: String = "Page1.0"
    
    
    
    func nextStep() {
        if currentPage < 4 {
               withAnimation {
                   currentPage += 1
               }
           }
        maketextForButton()
        if currentPage == 1 {
            shuoldRequestReview = true
        }
        if currentPage > 2  {
            showTermOfUseAndPrivacy = true
        }
    }
    
    private func maketextForButton() {
        if currentPage == 0 {
            textForButton = "Start"
        } else if currentPage > 0 && currentPage < 3 {
            textForButton = "Continue"
        } else if currentPage == 3{
            textForButton = "Try Free Trial & Continue"
        } else {
            textForButton = "Continue"
        }
        changeBg()
    }
    
    private func changeBg() {
        bgTitel = "Page\(currentPage + 1).0"
    }
}
