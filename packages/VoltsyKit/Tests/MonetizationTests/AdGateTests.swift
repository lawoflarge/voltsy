// Tests/MonetizationTests/AdGateTests.swift
import Testing
@testable import Monetization

@Suite("AdGate")
struct AdGateTests {
    @Test("Pro never sees ads, even with consent and past the grace period")
    func proNeverSeesAds() {
        #expect(AdGate.shouldShowAds(isPro: true, hasConsent: true,
                                     completedSessions: 99, graceSessions: 3) == false)
    }

    @Test("no consent suppresses ads")
    func noConsent() {
        #expect(AdGate.shouldShowAds(isPro: false, hasConsent: false,
                                     completedSessions: 99, graceSessions: 3) == false)
    }

    @Test("within the grace period free users see no ads yet")
    func withinGrace() {
        #expect(AdGate.shouldShowAds(isPro: false, hasConsent: true,
                                     completedSessions: 2, graceSessions: 3) == false)
    }

    @Test("eligible free user past grace with consent sees ads")
    func eligible() {
        #expect(AdGate.shouldShowAds(isPro: false, hasConsent: true,
                                     completedSessions: 3, graceSessions: 3) == true)
    }
}
