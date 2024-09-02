import { useState, useEffect } from "react";
import { useWallet } from "@aptos-labs/wallet-adapter-react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { useQuery, useQueryClient } from "@tanstack/react-query";
import { toast } from "@/components/ui/use-toast";
import { aptosClient } from "@/utils/aptosClient";

import { AuctionDetails } from "@/components/interface/AuctionDetails";

import { getAuction } from "@/view-functions/getAuction";
import { placeAuctionBid } from "@/entry-functions/placeAuctionBid";
import { closeAuction } from "@/entry-functions/closeAuction";
import { collectAuctionMoney } from "@/entry-functions/collectAuctionMoney";

export function DisplayAuctionDetail() {
  const { account, signAndSubmitTransaction } = useWallet();
  const queryClient = useQueryClient();

  const [auction, setAuction] = useState<AuctionDetails>();
  const [bidAmount, setBidAmount] = useState(0);

  const { data } = useQuery({
    queryKey: ["get-auction"],
    refetchInterval: 10_000,
    queryFn: async () => {
      try {
        const auctionDetails = await getAuction();
        return {
          auctionDetails,
        };
      } catch (error: any) {
        toast({
          variant: "destructive",
          title: "Error",
          description: error,
        });
        return {
          auctionDetails: [],
        };
      }
    },
  });

  useEffect(() => {
    if (data) {
      setAuction(data.auctionDetails as AuctionDetails);
    }
  }, [data]);

  const placeBid = async () => {
    if (!account || !bidAmount) {
      return;
    }
    try {
      const decimal = 100_000_000;
      const committedTransaction = await signAndSubmitTransaction(
        placeAuctionBid({
          bidAmount: bidAmount * decimal,
        }),
      );
      const executedTransaction = await aptosClient().waitForTransaction({
        transactionHash: committedTransaction.hash,
      });
      queryClient.invalidateQueries();
      toast({
        title: "Success",
        description: `Transaction succeeded, hash: ${executedTransaction.hash}`,
      });
      setBidAmount(0);
    } catch (error) {
      console.error(error);
      setBidAmount(0);
    }
  };

  const endAuction = async () => {
    if (!account) {
      return;
    }
    try {
      const committedTransaction = await signAndSubmitTransaction(closeAuction());
      const executedTransaction = await aptosClient().waitForTransaction({
        transactionHash: committedTransaction.hash,
      });
      queryClient.invalidateQueries();
      toast({
        title: "Success",
        description: `Transaction succeeded, hash: ${executedTransaction.hash}`,
      });
    } catch (error) {
      console.error(error);
    }
  };

  const claimAuctionMoney = async () => {
    if (!account) {
      return;
    }
    try {
      const committedTransaction = await signAndSubmitTransaction(collectAuctionMoney());
      const executedTransaction = await aptosClient().waitForTransaction({
        transactionHash: committedTransaction.hash,
      });
      queryClient.invalidateQueries();
      toast({
        title: "Success",
        description: `Transaction succeeded, hash: ${executedTransaction.hash}`,
      });
    } catch (error) {
      console.error(error);
    }
  };

  return (
    <div>
      {auction && (
        <div className="p-6 bg-white rounded-lg shadow-md">
          {/* Header: Seller Information */}
          <div className="flex justify-between items-center border-b pb-4 mb-4">
            <h2 className="text-xl font-semibold">Auction by {auction.seller}</h2>
            <span className="text-sm text-gray-600">{auction.auction_ended ? "Auction Ended" : "Auction Ongoing"}</span>
          </div>

          {/* Main Content: Auction Details */}
          <div className="flex flex-col space-y-4">
            {/* Auction Image */}
            <div className="flex flex-col items-center">
              <span className="font-medium mb-2">Auction Image:</span>
              <img src={auction.auction_url} alt="Auction Item" className="max-w-full h-auto rounded-lg shadow-sm" />
            </div>

            {/* Start Price */}
            <div className="flex items-center">
              <span className="font-medium w-1/3">Start Price:</span>
              <span className="text-gray-700 w-2/3">${+auction.start_price / 1_00_000_000} APT</span>
            </div>

            {/* Highest Bidder */}
            <div className="flex items-center">
              <span className="font-medium w-1/3">Highest Bidder:</span>
              <span className="text-gray-700 w-2/3">{auction.highest_bidder.vec[0] || "No bids yet"}</span>
            </div>

            {/* Highest Bid */}
            <div className="flex items-center">
              <span className="font-medium w-1/3">Highest Bid:</span>
              <span className="text-gray-700 w-2/3">
                {auction.highest_bid.vec[0] !== undefined
                  ? `$${auction.highest_bid.vec[0] / 1_00_000_000} APT`
                  : "No bids yet"}
              </span>
            </div>

            {/* Auction End Time */}
            <div className="flex items-center">
              <span className="font-medium w-1/3">Auction End Time:</span>
              <span className="text-gray-700 w-2/3">{new Date(auction.auction_end_time * 1000).toLocaleString()}</span>
            </div>
          </div>

          {/* Bid Input and Button */}
          <div className="mt-6 flex flex-col items-center space-y-4">
            <div className="flex items-center space-x-4 w-full">
              <Input
                type="number"
                className="w-2/3 p-2 border rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                value={bidAmount}
                placeholder="0.00"
                onChange={(e) => setBidAmount(+e.target.value)}
              />

              <Button
                className="w-1/3 p-2 bg-blue-500 text-white rounded-lg
               hover:bg-blue-600 focus:outline-none focus:ring-2 focus:ring-blue-500"
                onClick={placeBid}
              >
                Place Bid
              </Button>
            </div>
          </div>

          <div className="mt-6 flex justify-between items-center w-full">
            {/* Left Button */}
            <Button
              onClick={endAuction}
              className="p-2 bg-red-500 text-white rounded-lg hover:bg-red-600 focus:outline-none focus:ring-2 focus:ring-red-500"
            >
              End Auction
            </Button>

            {/* Right Button */}
            <Button
              onClick={claimAuctionMoney}
              className="p-2 bg-green-500 text-white rounded-lg hover:bg-green-600 focus:outline-none focus:ring-2 focus:ring-green-500"
            >
              Collect Auction Money
            </Button>
          </div>
        </div>
      )}
    </div>
  );
}
