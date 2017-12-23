# DOCADEMIC MTC Token

### The following code represents the contracts to be deployed on ethereum network for the ICO of the MTC Token.

For further information:
* [MTC ICO](https://ico.docademic.com)
* [Whitepaper](https://cdn.docademic.com/documents/Docademic+ICO+White+Paper.pdf)
---

### Basic contracts list:

#### /contracts/MultiSigWallet.sol
	Will be use as the main account which will hold all the tokens and controls every single transaction of the Token contract.

#### /contracts/Mtc.sol
	This is the token contract who takes care of the balances.
    The owner of this contracts is the MultiSigWallet.

#### /contracts/CrowdSale.sol
	This contract manage all the sale.
    Will move the tokens in a period of time with the aproval of the MultiSigWallet contract.

---
[contact](mailto:github@docademic.com)