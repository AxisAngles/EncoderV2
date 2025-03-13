local function computePayment(principal, interestRate, loanTerm)
	local k = interestRate*loanTerm
	return k/(1 - math.exp(-k))*principal
end

local function computePrincipal(principal, interestRate, paymentRate, time)
	local r = paymentRate/interestRate
	local k = interestRate*time
	return r + math.exp(k)*(principal - r)
end


local function computePaymentRate(principal, interestRate, loanTerm)
	return computePayment(principal, interestRate, loanTerm)/loanTerm
end

local principal = 559000
local loanTerm = 15
local loanRate = 0.045
local paymentRate = computePaymentRate(principal, loanRate, loanTerm)


local stockPrincipal = principal
local housePrincipal = principal

stockPrincipal = computePrincipal(stockPrincipal, 0.05, paymentRate, 7.5)
housePrincipal = computePrincipal(housePrincipal, loanRate, paymentRate, 7.5)


stockPrincipal = computePrincipal(stockPrincipal, 0.15, paymentRate, 7.5)
housePrincipal = computePrincipal(housePrincipal, loanRate, paymentRate, 7.5)

print(stockPrincipal)
print(housePrincipal)


-- this is what is in the stock market
-- rate is 10%
-- print(computePrincipal(principal, 0.1, paymentRate, 15))
-- print(paymentRate*15)



--print(computePrincipal(principal, interestRate, paymentRate, 3))

--print(computePrincipal(principal, interestRate, paymentRate, 1+1/12))


-- local function simulate(stocks, loan, stocksRate, loanRate, years)
-- 	for i = 1, years do
-- 		stocks
-- 	end
-- end