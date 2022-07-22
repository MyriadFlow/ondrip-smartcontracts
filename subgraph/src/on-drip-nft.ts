import { BigInt, Bytes, log } from "@graphprotocol/graph-ts"
import {
  AccountMinted,
  SubscriptionStatus,
  SubscriptionUpdate,
  Transfer,
  CredientialsUpdated,
  SubsTimeUpdated,
} from "../generated/OnDripNFT/OnDripNFT"
import {
  SubToken,
  User,
} from "../generated/schema"

function createUser(id: string): void {
  let user = User.load(id);
  if (!user) {
    user = new User(id);
    user.save();
  }
}

export function handleTransfer(event: Transfer): void {
  let token = SubToken.load(event.params.tokenId.toString());
  if (token) {
    token.owner = event.params.to.toHexString();
    token.save();
    createUser(token.owner);
    token.save();
  }
}

export function handleSubscriptionUpdate(event: SubscriptionUpdate): void {
  let token = SubToken.load(event.params._tokenID.toString());
  if (token) {
    token.accountOwner = event.params._receiver.toHexString();
    token.owner = event.params._renter.toHexString();
    token.save();
  }
}

export function handleSubsTimeUpdated(event: SubsTimeUpdated): void {
  let token = SubToken.load(event.params.tokenId.toString());
  if (token) {
    token.subsTime = event.params.subscriptionTime;
    token.save()
  }
}

export function handleSubscriptionStatus(event: SubscriptionStatus): void {
  let token = SubToken.load(event.params._tokenID.toString());
  if (token) {
    token.accountOwner = event.params._receiver.toHexString();
    token.owner = event.params._renter.toHexString();
    token.active = event.params._active
    token.save();
  }
}

export function handleAccountMinted(event: AccountMinted): void {
  let token = SubToken.load(event.params._id.toString());
  if (!token) {
    token = new SubToken(event.params._id.toString())
    token.createdAtTimestamp = event.block.timestamp
    token.accountOwner = event.params._accountOwner.toHexString()
    token.owner = event.params._accountOwner.toHexString();
    token.active = event.params._active;
    token.rateAmount = event.params._rateAmount
    token.renewalFee = event.params.__renewalFee
    token.description = event.params._description
    token.subsTime = new BigInt(0);
    token.credientials = "";
    token.renewalFee = event.params.__renewalFee
    token.save()
    createUser(token.accountOwner)
  }
}

export function handleCredientialsUpdated(event: CredientialsUpdated): void {
  let token = SubToken.load(event.params._tokenID.toString());
  if (!token) {
    log.error("token with tokenId {} doesn't exist", [event.params._tokenID.toString()])
    return
  }
  token.credientials = event.params.credientials;
  token.save()
}