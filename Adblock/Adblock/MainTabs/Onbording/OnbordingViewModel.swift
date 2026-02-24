

import SwiftUI
import Combine

class OnbordingViewModel: ObservableObject {
    private weak var coordinator: AppCoordinator?
    
    @Published var currentPage: Int = 0
    @Published var textForButton: String  = "Start".localized
    @Published var shuoldRequestReview: Bool = false
    @Published var showTermOfUseAndPrivacy: Bool = false
    @Published var bgTitel: String = "Page1.0"
    @Published var completeOnbording: Bool = false
    
    private let privacy: String =  "https://example.com/privacy"
    private let terms: String = "https://example.com/terms"
    
    
    init(coordinator: AppCoordinator){
        self.coordinator = coordinator
    }
    
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
        if currentPage == 4 {
            finishOnbording()
        }
    }
    
    private func maketextForButton() {
        if currentPage == 0 {
            textForButton = "Start".localized
        } else if currentPage > 0 && currentPage < 3 {
            textForButton = "Continue".localized
        } else if currentPage == 3{
            textForButton = "Try Free Trial & Continue".localized
        } else {
            textForButton = "Continue".localized
        }
        changeBg()
    }
    
    private func changeBg() {
        bgTitel = "Page\(currentPage + 1).0"
    }
    
    func finishOnbording() {
        coordinator?.finishOnbording()
    }
    
    func openPrivacyPolicy() {
        if let url = URL(string: privacy) {
            UIApplication.shared.open(url)
        }
    }
    
    func openTermsOfService() {
        if let url = URL(string: terms) {
            UIApplication.shared.open(url)
        }
    }
}
