<h1>HST - Hydro Security Tokens</h1>

<h3>Description</h3>

This is a set of Ethereum Smart Contracts which work on top of Hydro Snowflake. They allow a validated Snowflake address to create standardized Security Tokens that can be issued, bought and sold, validated, transferred, paid as dividends, and destroyed.

Architecture draft:

<p>
  <img src="https://github.com/juanlive/hst/blob/master/images/HST%20Securities%20Architecture.png" width="500">
</p>

<h3>To run tests:</h3>

1. Run the following:
npm install

2. Build dependencies with:
npm run build

3. Spin up a development blockchain using:
npm run chain

4. Then in another console window, run this:
npm run test

You can find an example test run in the file test.txt


<h3>Features (some are yet work-in-progress):</h3>

    Create Security Token - unique IDs are attributed to each token, called a Hydro Security Token or HST

    Define HST Rules - create a dictionary of rules that can be applied to the HST
    
    KYC Approval - n-chain KYC approval from off-chain KYC provider(s) of token issuer and buyers/sellers for defined ruleset

    AML Approval - on-chain AML approval from off-chain AML provider(s) for token issuer and buyers/sellers for defined ruleset

    Limit Owners - limit ownership percentage, or HYDRO amount for any HST

    Legal Approval - on-chain legal approval from off-chain legal providers to prove rightful creation, ownership, and structure of security token

    Legal Contracts - tie the HST to legal contracts and terms/conditions written off-chain via Hydro Ice.

    Restricted Transfers - override normal ERC-20 transfer methods to block transfers of HST between wallets if not on a KYC/AML whitelist

    Lockup Periods - set rules to lock token transfers and buy/sells for a period of X time

    Admin Function - an admin or issuer can modify rules, whitelist/blacklist, lock, freeze, or stop token transfers at any time

    Participant Functions - send and receive a token tied to ERC-1484 wallet ID, lockup, freeze, blacklist any ID

    HST Escrow - keep HYDRO tokens in escrow contract within ERC-1484 of issuer, until offering is closed, release back to ERC-1484 wallet ID of subscriber from escrow if conditions in legal contract aren’t met

    Subscription - use the Snowflake Subscription task to create a framework for payments and recurring subscriptions to a securitization

    Authenticate - use Hydro Raindrop to authenticate issuance, purchase/sale, transfer

    Carried Interest - calculate carried interest based on the Interest Smart Contract utility function (link when posted)

    Interest Payout - payout carried interest/management fee to token issuer on a set schedule to defined wallet IDs on the whitelist

    Dividend Payout - payout dividend from admin pro-rata to Snowflake wallet holders in HYDRO
    

<h3>HSTOken - General Description and Usage</h3>

Constructor

Required values

Provided by owner:
- bytes32 name
- string description
- string symbol
- uint8 decimals

Provided by system (HSToken Fabric):
- id
- HydroToken address
- IdentityRegistry address
- Raindrop address?
- ServiceRegistry address

Token initializes in stage = SETUP
The owner has 15 days to fill the main parameters to setup the token*.
3 functions shall be called to setup the token, each one with their corresponding parameters:
- set_MAIN_PARAMS
- set_STO_FLAGS
- set_STO_PARAMS

After calling these three functions, the owner can call 
- stagePrelaunch() 

to initiate the Token. stage = PRELAUNCH

During Prelaunch, the owner can add up to 3 KYC, AML and Legal resolvers with:
- addKYCResolver(address)
- addAMLResolver(address)
- addLegalResolver(address)

As well as:
- removeKYCResolver(address)
- etc

At any time, the owner can add or remove bulk EIN identities from whitelist or to the blacklist
- addWhitelist(uint[])
- addBlacklist(uint[])

Owner can activate the token with:
- stageActivate()
Token will change to stage = ACTIVE

Once activated, buyers can start buying the tokens. According with the configuration at setup, the token can accept Ethers and/or HydroTokens.
- buyTokens(string _coin, uint _amount)
_coin should be "ETH" or "HYDRO".
_amount is only required with "HYDRO", and specifies the amount of HydroTokens to pay, which should be approved in the HydroToken for the HSToken to use.

According to the token configuration, user should be required to be in a whitelist, and should be approved by KYC, AML and/or Legal resolvers.

There can be restrictions of amount per investor, total amount of tokens, etc.

Issuing will end once endDate parameter has been reached.
token will be in stage = FINALIZED
Once issuing has finalized, the HSToken will be able to be transacted as normal tokens.

* The dApp responsible of generating the HSTokens could opt to require all parameters at a time and make all the calls at a time. The system is designed for the dApp to be able to allow users to create their token first, without much to consider, and then give them 15 days to think about all the details. The token will be reserved in the blockhain for 15 days. If it has not been configured after that time, the token will be considered non existent.


<h3>Granting a user the OK to buy a Token - Javascript Example</h3>

We use a  group of pre-loaded contracts which we stored in the “instances” object array.
Also note that most steps are done by user number 1 (the token owner) but changing the user KYC status must be done by user number 2 (the service provider).
To allow a buyer to buy a Hydro Security Token, you need to follow this 6-steps recipe.


1. Appoint the Token to the Token Registry

<pre><code>
await instances.TokenRegistry.appointToken(
        tokenDummyAddress,
        web3.utils.fromAscii('TEST'),
        web3.utils.fromAscii('TestToken'),
        'just-a-test',
        10,
        {from: users[1].address}
)
</code></pre>

2. Assign Token buyer values in the Buyer Registry

<pre><code>
await instances.BuyerRegistry.assignTokenValues(
        tokenDummyAddress,
        '21', // minimum age
        '50000', // minimum net worth
        '36000', // minimum salary
        true, // accredited investor status required
        {from: user[1].address}
  )
</code></pre>

3. Add the Buyer to the Buyer Registry

<pre><code>
await instances.BuyerRegistry.addBuyer(
        '21', // EIN
        'Test first name 1',
        'Test last name 1',
        web3.utils.fromAscii('GMB'),
        '1984', // year of birth
        '12', // month of birth
        '12', // day of birth
        '100000', // net worth
        '50000', // salary
        {from: users[1].address}
  )
</code></pre>

4. Add a KYC Service to the Service Registry

<pre><code>
await instances.ServiceRegistry.addService(
        newToken.address,
        '3',
        web3.utils.fromAscii("KYC"),
        {from: users[1].address}
    )
</code></pre>

5. Assign a KYC Service to the Buyer in the Buyer Registry

<pre><code>
await instances.BuyerRegistry.addKycServiceToBuyer(
        '1',
        newToken.address,
        '3',
        {from: users[1].address}
  )
</code></pre>

6. Set KYC Status for the Buyer in the Buyer Registry

<pre><code>
await instances.BuyerRegistry.setBuyerKycStatus(
            '21',
        true,
            {from: users[2].address}
      )
</code></pre>
