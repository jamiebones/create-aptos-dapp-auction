import { InputTransactionData } from "@aptos-labs/wallet-adapter-react";

export const collectAuctionMoney = (): InputTransactionData => {
  
  return {
    data: {
      function: `${import.meta.env.VITE_MODULE_ADDRESS}::auction_contract::collect_auction_money`,
      functionArguments: [],
    },
  };
};













