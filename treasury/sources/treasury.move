module 0x20e3e402d0a714f636c25efd16080ea7718ee3992333b3e8d8080c2a64d2d014::treasury {

    use std::vector;
    use sui::tx_context::{Self, TxContext};
    use sui::coin::{Self, Coin};
    use sui::object;
    use sui::transfer;
    use sui::event;

    const ENotAuthorized: u64 = 1;
    const ENotEnoughSignatures: u64 = 2;

    // Visibility added → public struct
    public struct Treasury has key {
        id: object::UID,
        owners: vector<address>,
        threshold: u64,
        balance: Coin<0x2::sui::SUI>,
    }

    // Visibility added → public struct
    public struct ExecutedEvent has copy, drop, store {
        executor: address,
        amount: u64,
    }

    public fun create_treasury(
        owners: vector<address>,
        threshold: u64,
        ctx: &mut TxContext
    ) {
        assert!(threshold > 0, ENotEnoughSignatures);
        assert!(threshold <= vector::length(&owners), ENotEnoughSignatures);

        let treasury = Treasury {
            id: object::new(ctx),
            owners,
            threshold,
            balance: coin::zero(ctx),
        };

        transfer::share_object(treasury);
    }

    public fun deposit(
        treasury: &mut Treasury,
        coins: Coin<0x2::sui::SUI>
    ) {
        coin::join(&mut treasury.balance, coins);
    }

    fun is_owner(t: &Treasury, addr: address): bool {
        let owners_ref = &t.owners;
        let len = vector::length(owners_ref);
        let mut i = 0;

        while (i < len) {
            if (*vector::borrow(owners_ref, i) == addr) return true;
            i = i + 1;
        };
        false
    }

    public fun execute_payment(
        treasury: &mut Treasury,
        amount: u64,
        signatures: vector<address>,
        recipient: address,
        ctx: &mut TxContext
    ) {
        assert!(vector::length(&signatures) >= treasury.threshold, ENotEnoughSignatures);

        let mut i = 0;
        while (i < vector::length(&signatures)) {
            assert!(
                is_owner(treasury, *vector::borrow(&signatures, i)),
                ENotAuthorized
            );
            i = i + 1;
        };

        let coin_out = coin::split(&mut treasury.balance, amount, ctx);
        transfer::public_transfer(coin_out, recipient);

        event::emit(ExecutedEvent {
            executor: tx_context::sender(ctx),
            amount,
        });
    }
}
