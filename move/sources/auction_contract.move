module auction::auction_contract {

    use std::signer;
    use std::string::{Self, String};
    use std::option::{Self, Option};
    use aptos_framework::timestamp;
    use aptos_framework::aptos_account;
    use aptos_framework::account::SignerCapability;
    use aptos_framework::account;
    use aptos_framework::coin;
    use aptos_framework::aptos_coin::AptosCoin;

    #[test_only]
    use aptos_framework::stake;



    //error constant
    const ERR_OBJECT_DONT_EXIST: u64 = 700;
    const ERR_BID_SMALLER_THAN_HIGHEST_BID: u64 = 705;
    const ERR_AUCTION_TIME_LAPSED: u64 = 706;
    const ERR_AUCTION_ENDED: u64 = 707;
    const ERR_AUCTION_TIME_NOT_LAPSED: u64 = 708;
    const ERR_AUCTION_STILL_RUNNING: u64 = 709;
    const ERR_NOT_THE_OWNER: u64 = 710;
    const ERR_BID_TOO_SMALL: u64 = 711;
    const ERR_AUCTION_NOT_ENDED: u64 = 712;

    const WALLET_SEED: vector<u8> = b"Wallet seed for the object";

    #[resource_group_member(group = aptos_framework::object::ObjectGroup)]
    struct AuctionData has key {
        seller: address,
        start_price: u64,
        highest_bidder: Option<address>,
        highest_bid: Option<u64>,
        auction_end_time: u64,
        auction_ended: bool,
        auction_url: String
    }

    struct AuctionDataDetails has copy, drop {
        seller: address,
        start_price: u64,
        highest_bidder: Option<address>,
        highest_bid: Option<u64>,
        auction_end_time: u64,
        auction_ended: bool,
        auction_url: String
    }

    #[resource_group_member(group = aptos_framework::object::ObjectGroup)]
    struct SignerCapabilityStore has key {
        signer_capability: SignerCapability,
    }

    fun init_module(creator: &signer) {
        create_contract_resource(creator);
        create_new_auction(creator, 86400);
    }

    fun create_contract_resource(creator: &signer){
        //create a resource account to hold the contract funds
        let (_, signer_capability) = account::create_resource_account(creator, WALLET_SEED);
        move_to(creator, SignerCapabilityStore { signer_capability });
    }

    fun get_auction_signer(): signer acquires SignerCapabilityStore {
        let signer_capability = &borrow_global<SignerCapabilityStore>(@auction).signer_capability;
        account::create_signer_with_capability(signer_capability)
    }

    fun create_new_auction(creator: &signer, bid_time: u64) {
        //create a resource account to hold the contract funds
        move_to(
            creator,
            AuctionData {
                seller: @auction ,
                start_price: 2000000,
                highest_bidder: option::none(),
                highest_bid: option::none(),
                auction_end_time: timestamp::now_seconds() + bid_time,
                auction_ended: false,
                auction_url: string::utf8(b"https://img.freepik.com/premium-photo/stunning-highresolution-depiction-krom-god-war-image-is-seamless-blend-photo_1164885-2776.jpg?w=1060"),
            }
        )

    }

    public entry fun place_auction_bid(
        bidder: &signer,
        bid_amount: u64
    ) acquires AuctionData, SignerCapabilityStore {

        let auction_data = borrow_global_mut<AuctionData>(@auction);
        let auction_signer = get_auction_signer();
        let resource_account_address = signer::address_of(&auction_signer);
        let bidder_address = signer::address_of(bidder);
        check_auction_ended(auction_data.auction_end_time);
        if (auction_data.auction_ended) {
            abort (ERR_AUCTION_ENDED)
        };
        if ( auction_data.start_price > bid_amount ){
            abort (ERR_BID_TOO_SMALL)
        };
        //check if the bid is greater than the existing highest bid
        let former_highest_bid: u64 = 0;
        if (option::is_some(&auction_data.highest_bid) && option::is_some(&auction_data.highest_bidder)) {
            former_highest_bid = *option::borrow(&auction_data.highest_bid);
        };
        //check if the user bid is greater than the former bid
        if (former_highest_bid > bid_amount) {
            abort (ERR_BID_SMALLER_THAN_HIGHEST_BID)
        };

        if ( former_highest_bid > 0 ){
            //make refunds here
            let former_highest_bidder = *option::borrow(&auction_data.highest_bidder);
            aptos_account::transfer(&auction_signer, former_highest_bidder, former_highest_bid);
        };


        auction_data.highest_bid = option::some(bid_amount);
        auction_data.highest_bidder = option::some(bidder_address);
        //pay the coin here
        aptos_account::transfer(bidder, resource_account_address, bid_amount);

    }

    fun check_auction_ended(auction_end_time: u64){
        if (timestamp::now_seconds() > auction_end_time) {
            abort (ERR_AUCTION_TIME_LAPSED)
        };
    }

    //close_auction
    public entry fun close_auction(
    ) acquires AuctionData,
    {
        //get the auction
        let auction = borrow_global_mut<AuctionData>(@auction);
        if (timestamp::now_seconds() < auction.auction_end_time) {
            abort (ERR_AUCTION_TIME_NOT_LAPSED)
        };
        if (auction.auction_ended) {
            abort (ERR_AUCTION_ENDED)
        };
        //end the auction
        auction.auction_ended = true;
    }

    public entry fun collect_auction_money(
    ) acquires AuctionData, SignerCapabilityStore
    {
        //get the auction
        let auction = borrow_global_mut<AuctionData>(@auction);
        let resource_account_signer = &get_auction_signer();
        if (!auction.auction_ended) {
            abort (ERR_AUCTION_NOT_ENDED)
        };
        //end the auction
        auction.auction_ended = true;
        let bid_amount = option::borrow(&auction.highest_bid);
        coin::transfer<AptosCoin>(resource_account_signer, @auction, *bid_amount);
    }


    #[view]
    public fun get_auction(): AuctionDataDetails acquires AuctionData {
        let auction = borrow_global<AuctionData>(@auction);
        let auction_details = AuctionDataDetails {
            seller: auction.seller,
            start_price: auction.start_price,
            highest_bidder: auction.highest_bidder,
            highest_bid: auction.highest_bid,
            auction_end_time: auction.auction_end_time,
            auction_ended: auction.auction_ended,
            auction_url: auction.auction_url
        };

        auction_details
    }


    #[test_only]
    fun setup_test(
        creator: &signer,
        owner_1: &signer,
        owner_2: &signer,
        aptos_framework: &signer,
    ) {
        timestamp::set_time_has_started_for_testing(aptos_framework);
        stake::initialize_for_test(&account::create_signer_for_test(@0x1));

        account::create_account_for_test(signer::address_of(aptos_framework));
        account::create_account_for_test(signer::address_of(creator));
        account::create_account_for_test(signer::address_of(owner_1));
        account::create_account_for_test(signer::address_of(owner_2));
        create_contract_resource(creator);
        create_new_auction(creator, 86400);
        test_mint_aptos(creator, owner_1, owner_2)
    }

    #[test_only]
    fun test_mint_aptos(creator: &signer,
                        owner_1: &signer,
                        owner_2: &signer) {
        stake::mint(creator, 10000000000);
        stake::mint(owner_1, 10000000000);
        stake::mint(owner_2, 10000000000);
    }

    #[test(creator = @auction, owner_1 = @0x124,
        owner_2 = @0x125,
        aptos_framework = @0x1, )]
    fun test_auction_creation(
        creator: &signer,
        owner_1: &signer,
        owner_2: &signer,
        aptos_framework: &signer
    ) acquires AuctionData {
        setup_test(creator, owner_1, owner_2, aptos_framework);
        let auction = get_auction();
        assert!(auction.seller == @auction, 400);

    }

    #[test(creator = @auction, owner_1 = @0x124,
        owner_2 = @0x125,
        aptos_framework = @0x1, )]
    fun test_first_depositor(
        creator: &signer,
        owner_1: &signer,
        owner_2: &signer,
        aptos_framework: &signer
    ) acquires AuctionData, SignerCapabilityStore {

        setup_test(creator, owner_1, owner_2, aptos_framework);
        let bid_amount:u64 = 3000000;
        place_auction_bid(owner_1, bid_amount);
        let auction_data = get_auction();
        let highest_bid = *option::borrow(&auction_data.highest_bid);
        assert!( highest_bid == bid_amount, 401);
    }

    #[test(creator = @auction, owner_1 = @0x124,
        owner_2 = @0x125,
        aptos_framework = @0x1, )]
    fun test_highest_bidder_deposit(
        creator: &signer,
        owner_1: &signer,
        owner_2: &signer,
        aptos_framework: &signer
    ) acquires AuctionData, SignerCapabilityStore {

        setup_test(creator, owner_1, owner_2, aptos_framework);
        let bid_amount1:u64 = 3000000;
        let bid_amount2:u64 = 4000000;

        let owner_1_address = signer::address_of(owner_1);
        let owner_2_address = signer::address_of(owner_2);

        let bal_before_owner_1 = coin::balance<AptosCoin>(owner_1_address);
        let bal_before_owner_2 = coin::balance<AptosCoin>(owner_2_address);

        place_auction_bid(owner_1, bid_amount1);
        place_auction_bid(owner_2 , bid_amount2);

        let contract_balance  = coin::balance<AptosCoin>(signer::address_of(&get_auction_signer()));
        let bal_after_owner_1 = coin::balance<AptosCoin>(owner_1_address);
        let bal_after_owner_2 = coin::balance<AptosCoin>(owner_2_address);
        //
        assert!(bal_before_owner_1 == bal_after_owner_1, 500);
        assert!(bal_before_owner_2 > bal_after_owner_2, 501);
        assert!(contract_balance == bid_amount2, 503);
    }

    #[test(creator = @auction, owner_1 = @0x124,
        owner_2 = @0x125,
        aptos_framework = @0x1, )]
    fun test_withdraw_auction_money(
        creator: &signer,
        owner_1: &signer,
        owner_2: &signer,
        aptos_framework: &signer
    ) acquires AuctionData, SignerCapabilityStore {

        setup_test(creator, owner_1, owner_2, aptos_framework);
        let bid_amount1:u64 = 3000000;
        let bid_amount2:u64 = 4000000;
        place_auction_bid(owner_1, bid_amount1);
        place_auction_bid(owner_2 , bid_amount2);

        timestamp::fast_forward_seconds(1727040012);

        let owner_balance_before  = coin::balance<AptosCoin>(@auction);
        close_auction();
        collect_auction_money();
        let owner_balance_after  = coin::balance<AptosCoin>(@auction);
        assert!(owner_balance_after > owner_balance_before, 600);

    }

}

// aptos account transfer --account superuser --amount 100
// aptos init --profile <profile-name>

