Straight
========
> Receive bitcoin payments directly into your wallet

> Website: http://straight.romansnitko.com

Straight is a built-in stateless gateway library written in Ruby.
It allows you to receive bitcoin payments for your online store. Drop in this library,
set your public key and start receiving payments. Your BIP32-compatible wallet will
see payments automatically without any need for integration with your database.

Straight cares about security and privacy. No private keys are stored on the server,
each order uses unique payment address. Straight notifies your application when payment is 
confirmed so you can ship away.

IMPORTANT: this is a gem, not a server. It has no state and is intended to use within
an application, such as Ruby On Rails. Most likely, you want
[straight-server](https://github.com/snitko/straight-server), it is a server,
which holds the state of all orders for you and has a RESTful API you can use
with any application written in any language or platform.

Bitcoin donations are appreciated: 1D3PknG4Lw1gFuJ9SYenA7pboF9gtXtdcD 

How it works
------------
1. Get a wallet that supports BIP32 keychains (e.g. bitWallet for iOS). 
2. Create an "account" and export its root extended public key (looks like xpub572b9e85...).
3. Install Straight via Gemfile into your Ruby application.
4. Create new Gateway with `Straight::Gateway.new`, set its properties.
5. Start creating bitcoin orders by calling `gateway.order_for_keychain_id(...)``
6. Set callbacks to get notified when payment is confirmed.
7. Your wallet automatically detects incoming funds. Profit!

A little bit of explanation is due here. *Gateway* is a class, which instances are payment processors for
each online store. That is, if you have 2 online stores, you'll probably want to have a Gateway for each.

This is because each instance would have different properties specific for each store (see Usage section).
For example, each gateway may have a different callback or a different number of transaction confirmations
required to set the order status to PAID.

A new *Order* is created when you would like to give your customer an address to pay for your product or service.
It will track whether new transactions arrived at the address, check how much money was sent and change its status
accordingly.

Installation
------------

    gem install straight

Usage
-----

    require 'straight'

    # Create a new gateway first and configure all the settings
    #
    gateway = Gateway.new
    gateway.pubkey                 = 'xpub12345'
    gateway.confirmations_required = 0
    gateway.order_class            = 'Straight::Order'
    gateway.default_currency       = 'BTC'
    gateway.name                   = 'my gateway'

    # Set the callback for orders' status changes
    # (see lib/straight/order.rb for status attribute values and their meanings)
    #
    gateway.order_callbacks = [
      lambda { |order| puts "Order status changed to #{order.status}" }
    ]

    # Create a new order
    #
    # Remember you should always use a new, unique keychain_id, should preferably
    # be consecutive.
    #
    order = gateway.order_for_keychain_id(amount: 1, keychain_id: 1)

    # Start tracking the order
    #
    Thread.new { order.start_periodic_status_check }


Including Straight::Module vs Using Straight::Order class
---------------------------------------------------------
As this library is intended to use within an application and is not a standalone software itself,
I made a decision to provide a simple way to integrate it into existing ORMs. While there is currently
no official documentation as to how integrate it into ActiveRecord, you should be able to easily do it
like this:

    class Order < ActiveRecord::Base
      include Straight::OrderModule
      ...
    end

Same goes for the `GatewayModule`. It works the same way with other ORMs, such as Sequel (on which
StraightServer is built).

The right way to implement this would be to do it the other way: inherit from `Straight::Order`, then
include `ActiveRecord`, but at this point `ActiveRecord` doesn't work this way. Furthermore, some other libraries, like `Sequel`,
also require you to inherit from them. Thus, the module.

When this module is included, it doesn't actually *include* all the methods, some are prepended (see Ruby docs on #prepend).
It is important specifically for getters and setters and as a general rule only getters and setters are prepended.

If you don't want to bother yourself with modules, please use `Straight::Order` class and simply create new instances of it.
However, if you are contributing to the library, all new functionality should go to either `Straight::OrderModule::Includable` or
`Straight::OrderModule::Prependable` (most likely the former).


Important Considerations
------------------------
There is no magical link between the wallet and your server. Server creates new addresses for each order
based on sequential indexes. Your wallet scans blockchain generating the same sequential addresses too
(using a sliding window of several addresses). In order for this to work, as you may have guessed already,
all orders should be indexed sequentially, not randomly.

Why can't we just derive new addresses from order UUID, or assign them to orders? The reason is that your
wallet will have to integrate with your very own database and it may be enormously cumbersome to implement
in a generic way. Alternative would be to create a wallet within Straight and make it generate and keep the
private keys, but this would be highly insecure. Keys stored on popular hosting solutions would quickly
invite all sorts of attacks to get money from them.


A note about Mycelium blockchain adapter
----------------------------------------
If you wish to use Mycelium blockchain adapter you MUST install bitcoind on your server (you may run it in offline mode, no need to download the whole blockchain!) and have a `bitcoin-cli` in your PATH. This
requirement is due to the need to parse raw bitcoin transaction received from Mycelium WAPI.
By default, Mycelium is included as a second (fallback) adapter and will only be used in case
BlockchainInfo one fails. It will not raise an exception until it actually tries to parse the trasaction
and finds there is no `bitcoin-cli` in PATH.

Requirements
------------
Ruby 2.1 or later.

Credits
-------
Authors:
[Roman Snitko](http://romansnitko.com) and
[Oleg Andreev](http://oleganza.com)

Licence: MIT (see the LICENCE file)
