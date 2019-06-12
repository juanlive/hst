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
    


Tutorial: How to issue a token


This tutorial shows you how to issue a new token using the Hydro Securities Token framework. Token creation and setup will be performed by calling functions in the HSToken smart contract. Instructions follow.


Token creation

1. Call the HSToken Constructor

The following are required values for the creation of a new token, and must be provided by the owner/issuer of the token, possibly through a dApp, or as parameters if invoking the smart contract directly.

- bytes32 name
- string description
- string symbol
- uint8 decimals

The following values will be provided by the system itself (in the future, by means of HSToken Factory or a dApp) meanwhile (for testing purposes) they must be manually provided:

- uint id
- address HydroToken: address of HydroToken*
- address IdentityRegistry: address of Identity Registry*
- address owner: EIN of owner/issuer will be obtained from this address and will be used to authenticate internally with the einOwner variable.

* these addresses are expected for in the constructor to allow for testing to be performed in different blockchains (Rinkeby, Kovan, MainNet, and so)



Once created, a new token initializes itself as being in stage = SETUP

During this stage the token:
is not active
its name is protected
The owner/issuer has 15 days to fill the main parameters to setup the token. This was made to facilitate the life of the token owner/issuer.

2. Token setup

To setup the token, 3 different functions shall be called, each one with their corresponding parameters:

    function set_MAIN_PARAMS(
        uint256 _hydroPrice, Price in HydroTokens
        uint256 _ethPrice, Price in ethers (will be deprecated)
        uint256 _beginningDate, Date of beginning of sale
        uint256 _lockEnds, Date of unlocking of token
        uint256 _endDate, End date of the presale
        uint256 _maxSupply, Max supply of tokens
        uint256 _escrowLimitPeriod, amount of time in seconds for escrow

    )

    function set_STO_FLAGS(
        bool _LIMITED_OWNERSHIP, Will the ownership be limited?
        bool _PERIOD_LOCKED, Will the token will be limited for a period?
        bool _PERC_OWNERSHIP_TYPE, Will ownership be limited by percentage?
        bool _HYDRO_AMOUNT_TYPE, Will be restricted by amount of hydrotokens?
        bool _ETH_AMOUNT_TYPE, Will be restricted by amount of ethers=
        bool _HYDRO_ALLOWED, This will be ever true
        bool _ETH_ALLOWED, This will be ever false
        bool _KYC_RESTRICTED, Will buyers be restricted by KYC?
        bool _AML_RESTRICTED, WIll buyers be restricted by AML?
        bool _WHITELIST_RESTRICTED, Whitelist restriction
        bool _BLACKLIST_RESTRICTED, Blacklist restriction
        bool _ETH_ORACLE, Will be an oracle for price in ethers (depr)
        bool _HYDRO_ORACLE Will be an oracle for price in Hydro Tokens?
    )

    function set_STO_PARAMS(
        uint256 _percAllowedTokens, if _PERC_OWNERSHIP_TYPE is true, this will be the percentage
        uint256 _hydroAllowed, if _HYDRO_AMOUNT_TYPE is true, this will be the limit
        uint256 _ethAllowed, if _ETH_AMOUNT_TYPE is true, this will be the limit
        uint256 _lockPeriod, if _PERIOD_LOCKED is true, this will be the period
        uint256 _minInvestors, minimum of investors allowed
        uint256 _maxInvestors, maximum of investors allowed
        address _ethOracle, address of oracle to update eth price of token (if any)
        address _hydroOracle, address of oracle to update hydro price of token (if any)
    )


3. Token pre-launch

After calling these three functions, the owner/issuer can call:

function stagePrelaunch() 

If all previously shown settings were correctly made, the token will be activated and it will be in stage = PRELAUNCH

During the pre-launch stage, the owner/issuer can add or remove KYC, AML and Legal resolvers by calling the following functions:

addKYCResolver(address)
addAMLResolver(address)
addLegalResolver(address)

removeKYCResolver(address)
removeAMLResolver(address)
removeLegalResolver(address)

At any time, the owner/issuer can add or remove bulk EIN identities from whitelist or blacklist by calling the following functions:

addWhitelist(uint[])
addBlacklist(uint[])



4. Token activation

Owner/issuer can activate the token by calling the function

stageActivate()

Token will change to stage = ACTIVE

Once activated, buyers can start buying the tokens. According with the configuration at setup, the token can be bought using Ethers and/or Hydro Tokens.

Function to buy tokens during the active stage:

buyTokens(string _coin, uint _amount)

_coin should be "ETH" or "HYDRO".
_amount is only required with "HYDRO", and specifies the amount of HydroTokens to pay, which should be approved in the HydroToken for the HSToken to use.

According to the token configuration, user should be required to be in a whitelist, and should be approved by KYC, AML and/or Legal resolvers.

There can be restrictions of amount per investor, total amount of tokens, quantity of investors, or new rules that can be added in the future.



5. Token issuing closes

Issuing will end once endDate parameter has been reached. When that occurs, token will change to stage = FINALIZED

Once issuing has finalized, the HSToken will be able to be transacted as ERC20 tokens, except that they should follow additional rules, as to be approved by external KYC or AML resolvers, and fulfill any other rules. They can also track the date of each portion of tokens sent in any transaction, if that can influentiate its value according to some pre-configured rule.



6. Token oraclizing

An Oracle can be assigned to the token, and it should call the following function to update the price of the token in Ethers:

updateEthPrice(uint)


Oracles can be assigned, replaced or revoked (by assigning a passive address) by the owner/issuer of the token, at any time, calling the function:

addEthOracle(address)



7. Other administrative functions

setLockUpPeriod(uint _lockEnds)

Locks the token for a period of time. Date of unlock expressed in unix timestamp.

lock() / unLock()

Lock/unlocks the token.

freeze(uint[]) / unfreeze(uint[])

Freezes/unfreezes bulk or individual EIN identities for using the token.

releaseHydroTokens()

Release HydroTokens held in escrow to the owner/issuer.




8. Public Getters

getTokenEINOwner()

isLocked()

isAlive()

getStage()

isSetupTime()

isPrelaunchTime( )

