module rtbplatform::rtbplatform {
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
    /**
     * Creates a new user with the specified details.
     * @param principal - The address of the user.
     * @param userName - The name of the user.
     * @param email - The email of the user.
     * @param userType - The type of the user (e.g., advertiser, publisher).
     * @param ctx - The transaction context.
     */
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
    /**
     * Initializes the wallet of the user with an initial balance.
     * @param user - The user whose wallet is initialized.
     * @param initial_balance - The initial balance to add to the wallet.
     * @param _ctx - The transaction context.
     */
    public entry fun initialize_user_wallet(
        user: &mut User,
        initial_balance: Coin<SUI>,
        _ctx: &mut TxContext
    ) {
        let added_balance = coin::into_balance(initial_balance);
        balance::join(&mut user.wallet, added_balance);
    }
    /**
     * Deposits funds into the user's wallet.
     * @param user - The user who is depositing funds.
     * @param amount - The amount to deposit.
     * @param ctx - The transaction context.
     */
    public entry fun deposit_funds(
        user: &mut User,
        amount: Coin<SUI>,
        ctx: &mut TxContext
    ) {
        assert!(tx_context::sender(ctx) == user.principal, EInvalidDeposit); // Add access control check
        let added_balance = coin::into_balance(amount);
        balance::join(&mut user.wallet, added_balance);
    }
    /**
     * Creates a new advert slot with the specified details.
     * @param title - The title of the advert.
     * @param details - The details of the advert.
     * @param audienceType - The audience type for the advert.
     * @param adSlots - The number of ad slots available.
     * @param duration - The duration of the advert in milliseconds.
     * @param clock - The clock to get the current time.
     * @param ctx - The transaction context.
     */
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
    /**
     * Places a bid for the specified advert.
     * @param advert - The advert for which the bid is placed.
     * @param amount - The amount of the bid.
     * @param details - The details of the bid.
     * @param ctx - The transaction context.
     */
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
    /**
     * Selects a bid for the specified advert.
     * @param bid - The bid to select.
     * @param advert - The advert for which the bid is selected.
     * @param ctx - The transaction context.
     */
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
    /**
     * Pays for an ad slot.
     * @param advert - The advert for which the ad slot is paid.
     * @param user - The user who is paying for the ad slot.
     * @param ctx - The transaction context.
     */
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
    /**
     * Withdraws funds from the user's wallet.
     * @param user - The user who is withdrawing funds.
     * @param amount - The amount to withdraw.
     * @param ctx - The transaction context.
     */
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
    /**
     * Checks if the end date of the advert has passed and resets the advert if expired.
     * @param advert - The advert to check.
     * @param clock - The clock to get the current time.
     * @param _ctx - The transaction context.
     */
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
    /**
     * Gets the details of the specified advert.
     * @param advert - The advert to get details for.
     * @returns The details of the advert.
     */
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
    // Struct for AdvertDetails
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












