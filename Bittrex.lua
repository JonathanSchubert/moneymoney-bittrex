-- Inofficial Bittrex Extension (www.bittrex.com) for MoneyMoney
-- Fetches balances from Bittrex API and returns them as securities
--
-- Username: Bittrex API Key
-- Password: Bittrex API Secret
--
-- Copyright (c) 2017 Jonathan Schubert
--
-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to deal
-- in the Software without restriction, including without limitation the rights
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
-- copies of the Software, and to permit persons to whom the Software is
-- furnished to do so, subject to the following conditions:
--
-- The above copyright notice and this permission notice shall be included in all
-- copies or substantial portions of the Software.
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
-- SOFTWARE.

WebBanking {
  version = 1.2,
  url = "https://bittrex.com",
  description = "Fetch balances from Bittrex API and list them as securities",
  services = { "Bittrex Account" },
}

local apiKey
local apiSecret
local currency
local apiUrlVersion = "v1.1"
local market = "Bittrex"
local accountNumber = "Main"

function SupportsBank(protocol, bankCode)
  return protocol == ProtocolWebBanking and bankCode == "Bittrex Account"
end

function InitializeSession(protocol, bankCode, username, username2, password, username3)
  apiKey = username
  apiSecret = password
  currency = "EUR"
end

function ListAccounts(knownAccounts)
  local account = {
    name = market,
    accountNumber = accountNumber,
    currency = currency,
    portfolio = true,
    type = "AccountTypePortfolio"
  }
  return {account}
end

function RefreshAccount(account, since)
  local s = {}
  local price_btc_eur

  -- Retrieve BTC price in EUR
  -- price_btc_eur = queryPublic_cmc('ticker/bitcoin/', '?convert=EUR')[1]['price_eur']
  price_btc_eur = queryPublic_bci('tobtc', '?currency=EUR&value=1000')
  price_btc_eur = 1 / price_btc_eur * 1000
  print("Price BTC/EUR:", price_btc_eur)

  local balances = queryPrivate_bittrex("account/getbalances")
  for key, value in pairs(balances) do
    local amount_btc
    local amount_eur
    local price = 1
    local status = true
    
    local currency = value["Currency"]
    local balance = value["Balance"]

    if currency == "BTC" then
      amount_btc = balance
      
    elseif currency == "USDT" then
      price = queryPublic_bittrex("public/getticker", "?market=USDT-BTC")['Last']
      amount_btc = balance / price
      
    else
      repl = queryPublic_bittrex("public/getticker", "?market=BTC-" .. currency)
      
      if repl == nil then
        print('Error 1: No price available on market for', currency)
        status = false
      else
        price = repl['Last']
      end
      
      if price == nil then
        print('Error 2: No price available on market for', currency)
        status = false
        price = 1
      end
      
      amount_btc = price * balance
      
    end
    
    amount_eur = amount_btc * price_btc_eur

    -- print(currency, balance)
    -- print('    ', 'price', price)
    -- print('    ', 'amount_btc', amount_btc)
    -- print('    ', 'amount_eur', amount_eur)

    if status then
      s[#s+1] = {
        name = currency,
        market = market,
        currency = nil,
        amount = amount_eur,
        quantity = balance,
        price = price * price_btc_eur
      }
    else
      s[#s+1] = {
        name = currency,
        market = market,
        currency = nil,
        amount = nil,
        quantity = nil,
        price = nil
      }
    end
  end

  return {securities = s}
end

function EndSession()
end

function bin2hex(s)
  return (s:gsub(".", function (byte)
    return string.format("%02x", string.byte(byte))
  end))
end

function queryPrivate_bittrex(method)
  local nonce = string.format("%d", MM.time())
  local path = string.format("/api/%s/%s?apikey=%s&nonce=%s", apiUrlVersion, method, apiKey, nonce)
  local apiSign = MM.hmac512(apiSecret, url .. path)
  local headers = {}
  headers["apisign"] = bin2hex(apiSign)

  connection = Connection()
  content = connection:request("GET", url .. path, nil, nil, headers)
  json = JSON(content)

  return json:dictionary()["result"]
end

function queryPublic_bittrex(method, query)
  local path = string.format("/api/%s/%s", apiUrlVersion, method)

  connection = Connection()
  content = connection:request("GET", url .. path .. query)
  json = JSON(content)

  return json:dictionary()["result"]
end

function queryPublic_cmc(method, query)
  local url = 'https://api.coinmarketcap.com'
  local path = string.format("/v1/%s", method)

  connection = Connection()
  content = connection:request("GET", url .. path .. query)
  json = JSON(content)

  return json:dictionary()
end

function queryPublic_bci(method, query)
  local url = 'https://blockchain.info'
  local path = string.format("/%s", method)

  connection = Connection()
  content = connection:request("GET", url .. path .. query)
  json = JSON(content)

  return json:dictionary()
end

-- SIGNATURE: MCwCFCa1DNX18VXtiCmd+4ywS+WgHH4HAhR646jUDgUhnVGvKT47UhBDWoEXRQ==
