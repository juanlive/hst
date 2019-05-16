HST - Hydro Security Tokens

This is a set of Ethereum Smart Contracts which work on top of Hydro Snowflake. They allow a validated Snowflake address to create standardized Security Tokens that can be issued, bought and sold, validated, transferred, paid as dividends, and destroyed.

Architecture draft:

<p>
  <img src="https://github.com/juanlive/hst/blob/master/images/HST%20Securities%20Architecture.png" width="500">
</p>

To run tests:

1. Run the following:
npm install

2. Build dependencies with:
npm run build

3. Spin up a development blockchain using:
npm run chain

4. Then in another console window, run this:
npm run test


Features:

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
    

HSTOken - General Description and Usage

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

