import { aptosClient } from "@/utils/aptosClient";

import { AuctionDetails } from "@/components/interface/AuctionDetails";

export const getAuction = async (): Promise<AuctionDetails> => {
  const auction = await aptosClient()
    .view<[AuctionDetails]>({
      payload: {
        function: `${import.meta.env.VITE_MODULE_ADDRESS}::auction_contract::get_auction`,
      },
    })
    .catch((error) => {
      console.error(error);
      return [];
    });

  return auction[0];
};
