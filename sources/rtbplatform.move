module rtbplatform::rtbplatform {
    // Imports
    use std::string::{String};
    use std::vector;
    use sui::sui::SUI;
    use sui::transfer;
    use sui::object::{Self, UID, ID};
    use sui::tx_context::{Self, TxContext};
    use sui::clock::{Self, Clock};
    use sui::coin::{Self, Coin};
    use sui::balance::{Self, Balance};
    use std::option::{Option, none, some, borrow};

    // Errors
    const ENotPublisher: u64 = 1;
    const EInsufficientBalance: u64 = 2;
    const ENotAdvertiser: u64 = 3;
    const EInvalidBidAmount: u64 = 4;
    const EUnauthorizedWithdrawal: u64 = 5;
    const EInvalidDeposit: u64 = 6;

    // Struct definitions

    // Advert struct
    struct Advert has key, store {
        id: UID,
        title: String,
        details: String,
        audienceType: String,
        publisher: address,
        advertiser: Option<address>,
        cost: u64,
        adSlots: u64,
        available: bool,
        endDate: u64,
        createdAt: u64,
    }

    // Bid struct
    struct Bid has key, store {
        id: UID,
        advertId: ID,
        amount: u64,
        details: String,
        advertiser: address,
    }

    // User struct
    struct User has key, store {
        id: UID,
        principal: address,
        userName: String,
        email: String,
        wallet: Balance<SUI>,
        userType: String,
        adverts: vector<ID>,
    }

    public entry fun create_user(
        principal: address,
        userName: String,
        email: String,
        userType: String,
        ctx: &mut TxContext
    ) {
        let user_id = object::new(ctx);
        let user = User {
            id: user_id,
            principal,
            userName,
            email,
            wallet: balance::zero(),
            userType,
            adverts: vector::empty<ID>(),
        };
        transfer::share_object(user);
    }

    public entry fun initialize_user_wallet(
        user: &mut User,
        initial_balance: Coin<SUI>,
        _ctx: &mut TxContext
    ) {
        let added_balance = coin::into_balance(initial_balance);
        balance::join(&mut user.wallet, added_balance);
    }

    public entry fun deposit_funds(
        user: &mut User,
        amount: Coin<SUI>,
        ctx: &mut TxContext
    ) {
        assert!(tx_context::sender(ctx) == user.principal, EInvalidDeposit); // Add access control check
        let added_balance = coin::into_balance(amount);
        balance::join(&mut user.wallet, added_balance);
    }

    public entry fun create_advert_slot(
        title: String,
        details: String,
        audienceType: String,
        adSlots: u64,
        duration: u64,
        clock: &Clock,
        ctx: &mut TxContext
    ) {
        let advert_id = object::new(ctx);
        let endDate = clock::timestamp_ms(clock) + duration;
        let advert = Advert {
            id: advert_id,
            title,
            details,
            audienceType,
            publisher: tx_context::sender(ctx),
            advertiser: none(),
            cost: 0,
            adSlots,
            available: true,
            endDate,
            createdAt: clock::timestamp_ms(clock),
        };
        transfer::share_object(advert);
    }

    public entry fun bid_ad_slots(
        advert: &mut Advert,
        amount: u64,
        details: String,
        ctx: &mut TxContext
    ) {
        assert!(amount >= 100, EInvalidBidAmount); // Add validation for bid amount

        let bid_id = object::new(ctx);
        let bid = Bid {
            id: bid_id,
            advertId: object::uid_to_inner(&advert.id),
            amount,
            details,
            advertiser: tx_context::sender(ctx),
        };
        transfer::share_object(bid);
    }

    public entry fun select_bid(
        bid: &Bid,
        advert: &mut Advert,
        ctx: &mut TxContext
    ) {
        assert!(tx_context::sender(ctx) == advert.publisher, ENotPublisher);

        advert.advertiser = some(bid.advertiser);
        advert.cost = bid.amount;
        advert.available = false;
    }

    // pay for adslot
    public entry fun pay_for_ad_slot(
        advert: &mut Advert,
        user: &mut User,
        ctx: &mut TxContext
    ) {
        let advertiser_address = *borrow(&advert.advertiser); // Corrected usage of borrow
        assert!(tx_context::sender(ctx) == advertiser_address, ENotAdvertiser);

        let advert_costing = coin::take(&mut user.wallet, advert.cost, ctx);
        transfer::public_transfer(advert_costing, advert.publisher);

        let id_advert = object::uid_to_inner(&advert.id);
        vector::push_back(&mut user.adverts, id_advert);
    }

    public entry fun withdraw_funds(
        user: &mut User,
        amount: u64,
        ctx: &mut TxContext
    ) {
        assert!(tx_context::sender(ctx) == user.principal, EUnauthorizedWithdrawal); // Add access control check
        assert!(balance::value(&user.wallet) >= amount, EInsufficientBalance);
        let withdrawn = coin::take(&mut user.wallet, amount, ctx);
        transfer::public_transfer(withdrawn, user.principal);
    }

    // check if end date has passed and end the advert free slots
    public entry fun check_advert_end_date(
        advert: &mut Advert,
        clock: &Clock,
        _ctx: &mut TxContext
    ) {
        if (clock::timestamp_ms(clock) >= advert.endDate) {
            advert.available = true;
            advert.advertiser = none();
            advert.cost = 0;
        }
    }

    // get advert details
    public entry fun get_advert_details(advert: &Advert): AdvertDetails {
        AdvertDetails {
            title: advert.title,
            details: advert.details,
            audienceType: advert.audienceType,
            publisher: advert.publisher,
            advertiser: advert.advertiser,
            cost: advert.cost,
            adSlots: advert.adSlots,
            available: advert.available,
            endDate: advert.endDate,
            createdAt: advert.createdAt,
        }
    }

    struct AdvertDetails has drop {
        title: String,
        details: String,
        audienceType: String,
        publisher: address,
        advertiser: Option<address>,
        cost: u64,
        adSlots: u64,
        available: bool,
        endDate: u64,
        createdAt: u64,
    }
}