
export interface AuctionDetails {
  seller: string; 
  start_price: number;
  highest_bidder: {vec: [string | undefined ]};
  highest_bid: {vec: [number | undefined ]};
  auction_end_time: number;
  auction_ended: boolean;
  auction_url: string;
}

