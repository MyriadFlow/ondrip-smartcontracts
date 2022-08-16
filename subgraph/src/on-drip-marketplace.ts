import { log } from "@graphprotocol/graph-ts";
import {
    MarketItemCreated,
    MarketItemRemoved,
    MarketItemSold,
    AuctionItemCreated,
    AuctionItemSold,
    Bid,
    Withdraw
} from "../generated/OnDripMarketplace/OnDripMarketPlace"
import { SubAuctionItem, SubMarketItem, SubToken } from "../generated/schema"

export function handleMarketItemCreated(event: MarketItemCreated): void {
    let marketItem = SubMarketItem.load(event.params.itemId.toString())
    if (!marketItem) {
        marketItem = new SubMarketItem(event.params.itemId.toString());
        marketItem.createdAtTimestamp = event.block.timestamp
    }

    let token = SubToken.load(event.params.tokenId.toString())
    if (token) {
        marketItem.itemId = event.params.itemId
        marketItem.nftContract = event.params.nftContract
        marketItem.owner = event.params.owner
        marketItem.seller = event.params.seller
        marketItem.token = event.params.tokenId.toString()
        marketItem.price = event.params.price
        marketItem.deleted = false
        marketItem.metaDataUri = event.params.metaDataURI
        marketItem.sold = false;
        marketItem.save()
    }

}

export function handleMarketItemSold(event: MarketItemSold): void {
    let marketItem = SubMarketItem.load(event.params.itemId.toString())
    if (!marketItem) {
        log.error("market item with itemId {} doesn't exist", [event.params.itemId.toString()])
        return
    }
    marketItem.owner = event.params.buyer;
    marketItem.sold = true;
    marketItem.save()
}

export function handleMarketItemRemoved(event: MarketItemRemoved): void {
    let marketItem = SubMarketItem.load(event.params.itemId.toString())
    if (!marketItem) {
        log.error("market item with itemId {} doesn't exist", [event.params.itemId.toString()])
        return
    }
    marketItem.deleted = true;
    marketItem.save()
}

export function handleAuctionItemCreated(event: AuctionItemCreated): void {
    let auctionItem = SubAuctionItem.load(event.params.itemId.toString())
    if (!auctionItem) {
        auctionItem = new SubAuctionItem(event.params.itemId.toString());
        auctionItem.createdAtTimestamp = event.block.timestamp
    }

    let token = SubToken.load(event.params.tokenId.toString())
    if (token) {
        auctionItem.nftContract = event.params.nftContract
        auctionItem.owner = event.params.owner
        auctionItem.seller = event.params.seller
        auctionItem.token = event.params.tokenId.toString()
        auctionItem.highestBid = event.params.highestBid;
        auctionItem.ended = false
        auctionItem.sold = false
        auctionItem.metaDataUri = event.params.metaDataURI
        auctionItem.started = event.params.started
        auctionItem.highestBidder = event.params.highestBidder
        auctionItem.endAt = event.params.endAt
        auctionItem.save()
    }

}

export function handleAuctionItemSold(event: AuctionItemSold): void {
    let auctionItem = SubAuctionItem.load(event.params.itemId.toString())
    if (!auctionItem) {
        log.error("auction item with itemId {} doesn't exist", [event.params.itemId.toString()])
        return
    }
    auctionItem.sold = true;
    auctionItem.save()
}

export function handleBid(event: Bid): void {
    let auctionItem = SubAuctionItem.load(event.params.itemid.toString())
    if (!auctionItem) {
        log.error("auction item with itemId {} doesn't exist", [event.params.itemid.toString()])
        return
    }
    auctionItem.highestBid = event.params.amount;
    auctionItem.highestBidder = event.params.sender;
    auctionItem.save()
}