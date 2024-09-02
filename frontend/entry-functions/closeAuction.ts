import { InputTransactionData } from "@aptos-labs/wallet-adapter-react";

export const closeAuction = (): InputTransactionData => {

  return {
    data: {
      function: `${import.meta.env.VITE_MODULE_ADDRESS}::auction_contract::close_auction`,
      functionArguments: [],
    },
  };
};










