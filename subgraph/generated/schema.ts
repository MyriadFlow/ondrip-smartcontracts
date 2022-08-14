// THIS IS AN AUTOGENERATED FILE. DO NOT EDIT THIS FILE DIRECTLY.

import {
  TypedMap,
  Entity,
  Value,
  ValueKind,
  store,
  Bytes,
  BigInt,
  BigDecimal
} from "@graphprotocol/graph-ts";

export class SubToken extends Entity {
  constructor(id: string) {
    super();
    this.set("id", Value.fromString(id));
  }

  save(): void {
    let id = this.get("id");
    assert(id != null, "Cannot save SubToken entity without an ID");
    if (id) {
      assert(
        id.kind == ValueKind.STRING,
        `Entities of type SubToken must have an ID of type String but the id '${id.displayData()}' is of type ${id.displayKind()}`
      );
      store.set("SubToken", id.toString(), this);
    }
  }

  static load(id: string): SubToken | null {
    return changetype<SubToken | null>(store.get("SubToken", id));
  }

  get id(): string {
    let value = this.get("id");
    return value!.toString();
  }

  set id(value: string) {
    this.set("id", Value.fromString(value));
  }

  get createdAtTimestamp(): BigInt {
    let value = this.get("createdAtTimestamp");
    return value!.toBigInt();
  }

  set createdAtTimestamp(value: BigInt) {
    this.set("createdAtTimestamp", Value.fromBigInt(value));
  }

  get accountOwner(): string {
    let value = this.get("accountOwner");
    return value!.toString();
  }

  set accountOwner(value: string) {
    this.set("accountOwner", Value.fromString(value));
  }

  get owner(): string {
    let value = this.get("owner");
    return value!.toString();
  }

  set owner(value: string) {
    this.set("owner", Value.fromString(value));
  }

  get credientials(): string {
    let value = this.get("credientials");
    return value!.toString();
  }

  set credientials(value: string) {
    this.set("credientials", Value.fromString(value));
  }

  get renewalFee(): BigInt {
    let value = this.get("renewalFee");
    return value!.toBigInt();
  }

  set renewalFee(value: BigInt) {
    this.set("renewalFee", Value.fromBigInt(value));
  }

  get rateAmount(): BigInt {
    let value = this.get("rateAmount");
    return value!.toBigInt();
  }

  set rateAmount(value: BigInt) {
    this.set("rateAmount", Value.fromBigInt(value));
  }

  get description(): string {
    let value = this.get("description");
    return value!.toString();
  }

  set description(value: string) {
    this.set("description", Value.fromString(value));
  }

  get subsTime(): BigInt {
    let value = this.get("subsTime");
    return value!.toBigInt();
  }

  set subsTime(value: BigInt) {
    this.set("subsTime", Value.fromBigInt(value));
  }

  get active(): boolean {
    let value = this.get("active");
    return value!.toBoolean();
  }

  set active(value: boolean) {
    this.set("active", Value.fromBoolean(value));
  }

  get marketItems(): Array<string> {
    let value = this.get("marketItems");
    return value!.toStringArray();
  }

  set marketItems(value: Array<string>) {
    this.set("marketItems", Value.fromStringArray(value));
  }
}

export class User extends Entity {
  constructor(id: string) {
    super();
    this.set("id", Value.fromString(id));
  }

  save(): void {
    let id = this.get("id");
    assert(id != null, "Cannot save User entity without an ID");
    if (id) {
      assert(
        id.kind == ValueKind.STRING,
        `Entities of type User must have an ID of type String but the id '${id.displayData()}' is of type ${id.displayKind()}`
      );
      store.set("User", id.toString(), this);
    }
  }

  static load(id: string): User | null {
    return changetype<User | null>(store.get("User", id));
  }

  get id(): string {
    let value = this.get("id");
    return value!.toString();
  }

  set id(value: string) {
    this.set("id", Value.fromString(value));
  }

  get subs(): Array<string> {
    let value = this.get("subs");
    return value!.toStringArray();
  }

  set subs(value: Array<string>) {
    this.set("subs", Value.fromStringArray(value));
  }

  get created(): Array<string> {
    let value = this.get("created");
    return value!.toStringArray();
  }

  set created(value: Array<string>) {
    this.set("created", Value.fromStringArray(value));
  }
}

export class SubAuctionItem extends Entity {
  constructor(id: string) {
    super();
    this.set("id", Value.fromString(id));
  }

  save(): void {
    let id = this.get("id");
    assert(id != null, "Cannot save SubAuctionItem entity without an ID");
    if (id) {
      assert(
        id.kind == ValueKind.STRING,
        `Entities of type SubAuctionItem must have an ID of type String but the id '${id.displayData()}' is of type ${id.displayKind()}`
      );
      store.set("SubAuctionItem", id.toString(), this);
    }
  }

  static load(id: string): SubAuctionItem | null {
    return changetype<SubAuctionItem | null>(store.get("SubAuctionItem", id));
  }

  get id(): string {
    let value = this.get("id");
    return value!.toString();
  }

  set id(value: string) {
    this.set("id", Value.fromString(value));
  }

  get nftContract(): Bytes {
    let value = this.get("nftContract");
    return value!.toBytes();
  }

  set nftContract(value: Bytes) {
    this.set("nftContract", Value.fromBytes(value));
  }

  get owner(): Bytes {
    let value = this.get("owner");
    return value!.toBytes();
  }

  set owner(value: Bytes) {
    this.set("owner", Value.fromBytes(value));
  }

  get seller(): Bytes {
    let value = this.get("seller");
    return value!.toBytes();
  }

  set seller(value: Bytes) {
    this.set("seller", Value.fromBytes(value));
  }

  get token(): string {
    let value = this.get("token");
    return value!.toString();
  }

  set token(value: string) {
    this.set("token", Value.fromString(value));
  }

  get sold(): boolean {
    let value = this.get("sold");
    return value!.toBoolean();
  }

  set sold(value: boolean) {
    this.set("sold", Value.fromBoolean(value));
  }

  get createdAtTimestamp(): BigInt {
    let value = this.get("createdAtTimestamp");
    return value!.toBigInt();
  }

  set createdAtTimestamp(value: BigInt) {
    this.set("createdAtTimestamp", Value.fromBigInt(value));
  }

  get metaDataUri(): string {
    let value = this.get("metaDataUri");
    return value!.toString();
  }

  set metaDataUri(value: string) {
    this.set("metaDataUri", Value.fromString(value));
  }

  get ended(): boolean {
    let value = this.get("ended");
    return value!.toBoolean();
  }

  set ended(value: boolean) {
    this.set("ended", Value.fromBoolean(value));
  }

  get highestBid(): BigInt {
    let value = this.get("highestBid");
    return value!.toBigInt();
  }

  set highestBid(value: BigInt) {
    this.set("highestBid", Value.fromBigInt(value));
  }

  get highestBidder(): Bytes {
    let value = this.get("highestBidder");
    return value!.toBytes();
  }

  set highestBidder(value: Bytes) {
    this.set("highestBidder", Value.fromBytes(value));
  }

  get started(): boolean {
    let value = this.get("started");
    return value!.toBoolean();
  }

  set started(value: boolean) {
    this.set("started", Value.fromBoolean(value));
  }

  get endAt(): BigInt {
    let value = this.get("endAt");
    return value!.toBigInt();
  }

  set endAt(value: BigInt) {
    this.set("endAt", Value.fromBigInt(value));
  }
}

export class SubMarketItem extends Entity {
  constructor(id: string) {
    super();
    this.set("id", Value.fromString(id));
  }

  save(): void {
    let id = this.get("id");
    assert(id != null, "Cannot save SubMarketItem entity without an ID");
    if (id) {
      assert(
        id.kind == ValueKind.STRING,
        `Entities of type SubMarketItem must have an ID of type String but the id '${id.displayData()}' is of type ${id.displayKind()}`
      );
      store.set("SubMarketItem", id.toString(), this);
    }
  }

  static load(id: string): SubMarketItem | null {
    return changetype<SubMarketItem | null>(store.get("SubMarketItem", id));
  }

  get id(): string {
    let value = this.get("id");
    return value!.toString();
  }

  set id(value: string) {
    this.set("id", Value.fromString(value));
  }

  get itemId(): BigInt {
    let value = this.get("itemId");
    return value!.toBigInt();
  }

  set itemId(value: BigInt) {
    this.set("itemId", Value.fromBigInt(value));
  }

  get nftContract(): Bytes {
    let value = this.get("nftContract");
    return value!.toBytes();
  }

  set nftContract(value: Bytes) {
    this.set("nftContract", Value.fromBytes(value));
  }

  get owner(): Bytes {
    let value = this.get("owner");
    return value!.toBytes();
  }

  set owner(value: Bytes) {
    this.set("owner", Value.fromBytes(value));
  }

  get price(): BigInt {
    let value = this.get("price");
    return value!.toBigInt();
  }

  set price(value: BigInt) {
    this.set("price", Value.fromBigInt(value));
  }

  get seller(): Bytes {
    let value = this.get("seller");
    return value!.toBytes();
  }

  set seller(value: Bytes) {
    this.set("seller", Value.fromBytes(value));
  }

  get token(): string {
    let value = this.get("token");
    return value!.toString();
  }

  set token(value: string) {
    this.set("token", Value.fromString(value));
  }

  get createdAtTimestamp(): BigInt {
    let value = this.get("createdAtTimestamp");
    return value!.toBigInt();
  }

  set createdAtTimestamp(value: BigInt) {
    this.set("createdAtTimestamp", Value.fromBigInt(value));
  }

  get metaDataUri(): string {
    let value = this.get("metaDataUri");
    return value!.toString();
  }

  set metaDataUri(value: string) {
    this.set("metaDataUri", Value.fromString(value));
  }

  get sold(): boolean {
    let value = this.get("sold");
    return value!.toBoolean();
  }

  set sold(value: boolean) {
    this.set("sold", Value.fromBoolean(value));
  }

  get deleted(): boolean {
    let value = this.get("deleted");
    return value!.toBoolean();
  }

  set deleted(value: boolean) {
    this.set("deleted", Value.fromBoolean(value));
  }
}
