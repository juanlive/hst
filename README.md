HST - Hydro Security Tokens

This is a set of Ethereum Smart Contracts which work on top of Hydro Snowflake. They allow a validated Snowflake address to create standardized Security Tokens that can be issued, bought and sold, validated, transferred, paid as dividends, and destroyed.

Architecture draft:

<p>
  <img src="https://github.com/juanlive/hst/blob/master/images/HST%20Securities%20Architecture.png" width="500">
</p>

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
    
