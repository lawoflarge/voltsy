// Sources/Monetization/ProStore.swift
// StoreKit 2 wrapper for the single €4.99 lifetime non-consumable. StoreKit's
// `Transaction.currentEntitlements` is the source of truth (no local persistence to forge),
// so Restore and reinstall just re-query it. `isPro` drives ad removal + Pro feature gating.
import Foundation
import StoreKit
import Observation

@MainActor
@Observable
public final class ProStore {
    public static let productID = "com.lawoflarge.voltsy.pro"

    public private(set) var product: Product?
    public private(set) var isPro = false
    public private(set) var purchaseInFlight = false

    private var updates: Task<Void, Never>?

    public init() {
        updates = observeTransactionUpdates()
        Task { await refresh() }
    }

    // No deinit-cancel: ProStore is an app-lifetime root object and the listener captures
    // `[weak self]`, so there's no retain cycle. (deinit is nonisolated and can't touch the
    // MainActor-isolated `updates` under Swift 6 anyway.)

    /// Localized price string for the paywall (falls back while the product loads).
    public var displayPrice: String { product?.displayPrice ?? "" }

    public func refresh() async {
        product = try? await Product.products(for: [Self.productID]).first
        await updateEntitlement()
    }

    public func purchase() async {
        guard let product, !purchaseInFlight else { return }
        purchaseInFlight = true
        defer { purchaseInFlight = false }
        guard let result = try? await product.purchase() else { return }
        if case .success(let verification) = result,
           case .verified(let transaction) = verification {
            await transaction.finish()
            await updateEntitlement()
        }
    }

    public func restore() async {
        try? await AppStore.sync()
        await updateEntitlement()
    }

    private func updateEntitlement() async {
        var owned = false
        for await result in Transaction.currentEntitlements {
            if case .verified(let t) = result,
               t.productID == Self.productID, t.revocationDate == nil {
                owned = true
            }
        }
        isPro = owned
    }

    private func observeTransactionUpdates() -> Task<Void, Never> {
        Task { [weak self] in
            for await _ in Transaction.updates {
                await self?.updateEntitlement()
            }
        }
    }
}
