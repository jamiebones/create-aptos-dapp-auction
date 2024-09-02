import { InputTransactionData } from "@aptos-labs/wallet-adapter-react";


export type PlaceBidArguments = {
    bidAmount: number;
};

export const placeAuctionBid = (args: PlaceBidArguments): InputTransactionData => {
  const {bidAmount } = args;
  return {
    data: {
      function: `${import.meta.env.VITE_MODULE_ADDRESS}::auction_contract::place_auction_bid`,
      functionArguments: [BigInt(bidAmount) ],
    },
  };
};


