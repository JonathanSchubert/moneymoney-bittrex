# MoneyMoney-Bittrex

This MoneyMoney extension fetches your Bittrex.com balances and returns them as securities.  
It will always return the securities as EUR. For the conversion BTC → EUR the blockchain.info API is used.  

## Extension Setup

Download the signed extension file `Bittrex.lua` from  
* the  [`dist` directory in this repository](https://github.com/JonathanSchubert/moneymoney-bittrex/blob/master/dist/Bittrex.lua), or  
* the [MoneyMoney Extensions](https://moneymoney-app.com/extensions/) page  

Just move the file to your MoneyMoney Extensions folder.   MoneyMoney will direct you to this folder by selecting 'Show database in finder' in the Help menu.  

## Account Setup

### Bittrex

1. Log in to your Bittrex account
2. Go to Settings → API Keys
3. Click "Add new API Key"
4. Enable for this new key pair only the check box 'read info'
5. If asked for, enter your 2 factor authentication code
6. Make sure to never use this key pair for any other application.

### MoneyMoney

Add a new account in MoneyMoney (type "Bittrex Account") and use your Bittrex API key as username and your Bittrex API secret as password.

### Links
https://www.moneymoney-app.com  
https://blockchain.info  
https://www.bittrex.com  
