

Straight
========

> Receive bitcoin payments directly into your wallet

Straight is a built-in stateless gateway to receive bitcoin payments for 
your online shop. Drop in this library, set your public key and start receiving payments.
Your BIP32-compatible wallet will see payments automatically without any need for integration
with your database.

Straight cares about security and privacy. No private keys are stored on the server,
each order uses unique payment address. Straight notifies your application when payment is 
confirmed so you can ship away.

How it works
------------

1. Get a wallet that supports BIP32 keychains (e.g. bitWallet for iOS). 
2. Create an "account" and exports its root extended public key (looks like xpub572b9e85...).
3. Install Straight via Gemfile into your Ruby application.
4. Set the exported public key using Straight::Gateway.new(pubkey: "xpub572b9...")
5. Start creating bitcoin orders by calling gateway.order\_for\_id(sequential\_index)
6. Get notified when the payment is confirmed: (TODO: complete this part with specifics)
7. Your wallet automatically detects incoming funds. Profit!

Important Considerations
------------------------

There is no magical link between the wallet and your server. Server creates new addresses for each order based on sequential indices. 
Your wallet scans blockchain generating the same sequential addresses too (using a sliding window of several addresses).
In order for this to work, as you may have guessed already, all orders should be indexed sequentially, not randomly.

Why can't we just derive new addresses from order UUID, or assign them to orders? The reason is that your wallet will have to integrate with 
your very own database and it may be enormously combersome to implement in a generic way. Alternative would be to create a wallet within Straight 
and make it generate and keep the private keys, but this would be highly insecure. Keys stored on popular hosting solutions would quickly invite 
all sorts of attacks to get money from them.

Authors
------

Roman Snitko <roman.snitko@gmail.com>

Oleg Andreev <oleganza@gmail.com>


MIT License
-----------

Copyright (c) 2014 Roman Snitko

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.




