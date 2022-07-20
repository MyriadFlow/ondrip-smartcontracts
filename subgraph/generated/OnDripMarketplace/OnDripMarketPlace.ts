// THIS IS AN AUTOGENERATED FILE. DO NOT EDIT THIS FILE DIRECTLY.

import {
  ethereum,
  JSONValue,
  TypedMap,
  Entity,
  Bytes,
  Address,
  BigInt
} from "@graphprotocol/graph-ts";

export class MarketItemCreated extends ethereum.Event {
  get params(): MarketItemCreated__Params {
    return new MarketItemCreated__Params(this);
  }
}

export class MarketItemCreated__Params {
  _event: MarketItemCreated;

  constructor(event: MarketItemCreated) {
    this._event = event;
  }

  get itemId(): BigInt {
    return this._event.parameters[0].value.toBigInt();
  }

  get nftContract(): Address {
    return this._event.parameters[1].value.toAddress();
  }

  get tokenId(): BigInt {
    return this._event.parameters[2].value.toBigInt();
  }

  get seller(): Address {
    return this._event.parameters[3].value.toAddress();
  }

  get owner(): Address {
    return this._event.parameters[4].value.toAddress();
  }

  get price(): BigInt {
    return this._event.parameters[5].value.toBigInt();
  }

  get sold(): boolean {
    return this._event.parameters[6].value.toBoolean();
  }
}

export class MarketItemSold extends ethereum.Event {
  get params(): MarketItemSold__Params {
    return new MarketItemSold__Params(this);
  }
}

export class MarketItemSold__Params {
  _event: MarketItemSold;

  constructor(event: MarketItemSold) {
    this._event = event;
  }

  get itemId(): BigInt {
    return this._event.parameters[0].value.toBigInt();
  }

  get tokenId(): BigInt {
    return this._event.parameters[1].value.toBigInt();
  }

  get buyer(): Address {
    return this._event.parameters[2].value.toAddress();
  }

  get price(): BigInt {
    return this._event.parameters[3].value.toBigInt();
  }
}

export class OnDripMarketPlace extends ethereum.SmartContract {
  static bind(address: Address): OnDripMarketPlace {
    return new OnDripMarketPlace("OnDripMarketPlace", address);
  }

  onDripNFT(): Address {
    let result = super.call("onDripNFT", "onDripNFT():(address)", []);

    return result[0].toAddress();
  }

  try_onDripNFT(): ethereum.CallResult<Address> {
    let result = super.tryCall("onDripNFT", "onDripNFT():(address)", []);
    if (result.reverted) {
      return new ethereum.CallResult();
    }
    let value = result.value;
    return ethereum.CallResult.fromValue(value[0].toAddress());
  }

  payoutAddress(): Address {
    let result = super.call("payoutAddress", "payoutAddress():(address)", []);

    return result[0].toAddress();
  }

  try_payoutAddress(): ethereum.CallResult<Address> {
    let result = super.tryCall(
      "payoutAddress",
      "payoutAddress():(address)",
      []
    );
    if (result.reverted) {
      return new ethereum.CallResult();
    }
    let value = result.value;
    return ethereum.CallResult.fromValue(value[0].toAddress());
  }

  platformFeeBasisPoint(): BigInt {
    let result = super.call(
      "platformFeeBasisPoint",
      "platformFeeBasisPoint():(uint96)",
      []
    );

    return result[0].toBigInt();
  }

  try_platformFeeBasisPoint(): ethereum.CallResult<BigInt> {
    let result = super.tryCall(
      "platformFeeBasisPoint",
      "platformFeeBasisPoint():(uint96)",
      []
    );
    if (result.reverted) {
      return new ethereum.CallResult();
    }
    let value = result.value;
    return ethereum.CallResult.fromValue(value[0].toBigInt());
  }
}

export class ConstructorCall extends ethereum.Call {
  get inputs(): ConstructorCall__Inputs {
    return new ConstructorCall__Inputs(this);
  }

  get outputs(): ConstructorCall__Outputs {
    return new ConstructorCall__Outputs(this);
  }
}

export class ConstructorCall__Inputs {
  _call: ConstructorCall;

  constructor(call: ConstructorCall) {
    this._call = call;
  }

  get _onDripNFT(): Address {
    return this._call.inputValues[0].value.toAddress();
  }

  get _platformFee(): BigInt {
    return this._call.inputValues[1].value.toBigInt();
  }
}

export class ConstructorCall__Outputs {
  _call: ConstructorCall;

  constructor(call: ConstructorCall) {
    this._call = call;
  }
}

export class CreateMarketItemCall extends ethereum.Call {
  get inputs(): CreateMarketItemCall__Inputs {
    return new CreateMarketItemCall__Inputs(this);
  }

  get outputs(): CreateMarketItemCall__Outputs {
    return new CreateMarketItemCall__Outputs(this);
  }
}

export class CreateMarketItemCall__Inputs {
  _call: CreateMarketItemCall;

  constructor(call: CreateMarketItemCall) {
    this._call = call;
  }

  get tokenId(): BigInt {
    return this._call.inputValues[0].value.toBigInt();
  }

  get price(): BigInt {
    return this._call.inputValues[1].value.toBigInt();
  }
}

export class CreateMarketItemCall__Outputs {
  _call: CreateMarketItemCall;

  constructor(call: CreateMarketItemCall) {
    this._call = call;
  }
}

export class CreateMarketSaleCall extends ethereum.Call {
  get inputs(): CreateMarketSaleCall__Inputs {
    return new CreateMarketSaleCall__Inputs(this);
  }

  get outputs(): CreateMarketSaleCall__Outputs {
    return new CreateMarketSaleCall__Outputs(this);
  }
}

export class CreateMarketSaleCall__Inputs {
  _call: CreateMarketSaleCall;

  constructor(call: CreateMarketSaleCall) {
    this._call = call;
  }

  get itemId(): BigInt {
    return this._call.inputValues[0].value.toBigInt();
  }
}

export class CreateMarketSaleCall__Outputs {
  _call: CreateMarketSaleCall;

  constructor(call: CreateMarketSaleCall) {
    this._call = call;
  }
}
