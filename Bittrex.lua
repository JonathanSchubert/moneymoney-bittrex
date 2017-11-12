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
  version = 1.0,
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

  local price_btc_eur = queryPublic2('ticker/bitcoin/', '?convert=EUR')[1]['price_eur']
  -- print(price_btc_eur)

  local balances = queryPrivate("account/getbalances")
  for key, value in pairs(balances) do
    local amount_btc
    local amount_eur
    local price = 1

    if value["Currency"] == "BTC" then
      amount_btc = value['Balance']
      amount_eur = amount_btc * price_btc_eur
    elseif value["Currency"] == "USDT" then
      price = queryPublic("public/getticker", "?market=USDT-BTC")['Last']
      amount_btc = value['Balance'] / price
      amount_eur = amount_btc * price_btc_eur
    else
      price = queryPublic("public/getticker", "?market=BTC-" .. value["Currency"])['Last']
      amount_btc = price * value['Balance']
      amount_eur = amount_btc * price_btc_eur
    end

    -- print(value['Currency'], value['Balance'])
    -- print('    ', 'price', price)
    -- print('    ', 'amount_btc', amount_btc)
    -- print('    ', 'amount_eur', amount_eur)

    s[#s+1] = {
      name = value["Currency"],
      market = market,
      currency = nil,
      amount = amount_eur,
      quantity = value['Balance'],
      price = price * price_btc_eur
    }
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

function queryPrivate(method)
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

function queryPublic(method, query)
  local path = string.format("/api/%s/%s", apiUrlVersion, method)

  connection = Connection()
  content = connection:request("GET", url .. path .. query)
  json = JSON(content)

  return json:dictionary()["result"]
end

function queryPublic2(method, query)
  local url2 = 'https://api.coinmarketcap.com'
  local path = string.format("/v1/%s", method)

  connection = Connection()
  content = connection:request("GET", url2 .. path .. query)
  json = JSON(content)

  return json:dictionary()

end
