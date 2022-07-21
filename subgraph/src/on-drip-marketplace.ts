import {
    MarketItemCreated,
    MarketItemRemoved,
    MarketItemSold,
} from "../generated/OnDripMarketplace/OnDripMarketPlace"
import { SubMarketItem, SubToken } from "../generated/schema"

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
        marketItem.forSale = true
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
        marketItem = new SubMarketItem(event.params.itemId.toString());
    }
    marketItem.owner = event.params.buyer;
    marketItem.sold = true;
    marketItem.save()
}

export function handleMarketItemRemoved(event: MarketItemRemoved): void {
    let marketItem = SubMarketItem.load(event.params.itemId.toString())
    if (!marketItem) {
        marketItem = new SubMarketItem(event.params.itemId.toString());
    }
    marketItem.deleted = true;
    marketItem.save()
}