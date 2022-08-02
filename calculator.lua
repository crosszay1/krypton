function characterPresent(stringParam, character)
    --[[
        This function returns true if and only if character is in stringParam.
    ]]--
    --Loop through stringParam:
    for i=1, #stringParam do
        --If the current character is character, return true.
        if stringParam:sub(i, i) == character then return true end
    end
    --If we go through the whole string without returning true, we get to this point.
    --This means we've checked every character and haven't found character, so we return false.
    return false
end

function getNumber(stringParam)
    --[[
        This function parses a number from the beginning of stringParam and also returns the rest of the string.
        For example, if stringParam is "23s", this function returns 23, "s".
        If there is no number at the beginning of stringParam (e.g., stringParam is "Hi"), then the function returns nil, stringParam.
    ]]--
    --These are all of the characters we would expect in a number.
    local validCharacters = "0123456789.-"
    --This is true if and only if we have found a digit.
    local foundDigit = false
    --This is the index of the character in stringParam we are currently looking at.
    local i = 1
    --This is the character in stringParams we are currently looking at.
    local currentCharacter = stringParam:sub(i, i)
    --We want to examine stringParam while the current character is a valid character:
    while characterPresent(validCharacters, currentCharacter) do
        --In the first character, get rid of the - from validCharacters because we do not want a negative sign after the number has already begun. Negative signs must always be the first character in a number.
        if i == 1 then validCharacters = "0123456789." end
        --If currentCharacter is a decimal point, then make get rid of the . and - from validCharacters because we only want one decimal point and a negative sign can not come after a decimal point.
        if currentCharacter == "." then validCharacters = "0123456789" end
        --If currentCharacter is a digit, then make foundDigit true:
        if characterPresent("0123456789", currentCharacter) then foundDigit = true end
        --Finally, increment i to go to the next character.
        i = i+1
        --If i has gone past the length of stringParam, then there are no more characters and the loop should be exited.
        if i > #stringParam then break end
        --Otherwise, update currentCharacter.
        currentCharacter = stringParam:sub(i, i)
    end
    --If we have not found a digit, then we have not found a number, so go back to the beginning of the string to signify that stringParam does not have a number at the beginning.
    if not foundDigit then i = 1 end
    --Parse the number from the beginningof the string up till i.
    local number = tonumber(stringParam:sub(1, i-1))
    --Finally, return the number and the rest of the string.
    return number, stringParam:sub(i, #stringParam)
end

function parseExpression(expression, expectEndParentheses)
    --[[
        This function parses expression and returns the mathematical value of expression along with the rest of expression that was not parsed.
        If expectEndParentheses is not specified, it defaults to false.
        If expectEndParentheses is false, then the whole expression is parsed. If the expression is valid, what is returned is the value of the expression along with the empty string.
        If expectEndParentheses is true, then the expression is parsed up until the first end parentheses without a matching beginning parentheses. If the expression is valid, what is returned is the value of the expression along with the rest of expression after the end parentheses.
        In both cases, if the expression is invalid, the. what is returned is nil along with an error message.
        For example:
        parseExpression("2+3") -> 5, ""
        parseExpression("Hi") -> nil, "Invalid input where number or '(' was expected"
        parseExpression("2+3)+5", true) -> 5, "+5"
    ]]--
    --This is true if and only if we are expecting an expression next instead of an operator.
    local expectingExpression = true
    --This is true if and only if the last expression examined was surrounded by parentheses.
    local lastExpressionWasParenthetical = false
    --These are all the operators in our parser.
    local operators = "+-/*^"
    --This is a list of all of the parts in our expression.
    local parts = {}
    --This is true if and only if we have found an unmatched end parentheses.
    local foundEndParentheses = false
    --If expectEndParentheses is not specified, make it default to false.
    expectEndParentheses = expectEndParentheses or false
    --We want to parse the expression until we have broken it up into all of its parts and there is nothing left to parse:
    while expression ~= "" do
        --Check if there is a number at the beginning of expression.
        local nextNumber, expressionAfterNumber = getNumber(expression)
        --This is the next character:
        local nextCharacter = expression:sub(1, 1)
        --This is the next piece of the expression, used in error messages:
        local nextPiece = expression:sub(1, 5)
        --Add " [end]" if expression has 5 characters or less to signify that this piece is the end of the expression
        if #expression <= 5 then nextPiece = nextPiece.." [end]" end
        --If we expect an expression:
        if expectingExpression then
            --If there is a beginning parentheses next, parse the expression inside the parentheses:
            if nextCharacter == "(" then
                --Parse the next expression by taking the beginning parentheses off and outting the rest of the expression into parseExpression. Also, make expectEndParentheses true so that the expression will only be parsed up to the next end parentheses that is not matched without this beginning parentheses.
                local nestedExpressionValue, expressionAfterParentheses = parseExpression(expression:sub(2, #expression), true)
                --If the value returned is nil, then parsing this expression must have caused an error, so return the error message.
                if nestedExpressionValue == nil then return nestedExpressionValue, expressionAfterParentheses end
                --Otherwise, insert the value into parts.
                table.insert(parts, nestedExpressionValue)
                --Also, update expression by going on to what's after the parentheses.
                expression = expressionAfterParentheses
                --Make lastExpressionWasParenthetical true.
                lastExpressionWasParenthetical = true
            --Otherwise, if there is no parentheses, parse the next number:
            else
                --If the next number is nil, then return an error message.
                if nextNumber == nil then return nil, "Expected number or '(', but found '"..nextPiece.."'" end
                --Otherwise, insert the number into parts.
                table.insert(parts, nextNumber)
                --Also, update expression by going on to what's after the number.
                expression = expressionAfterNumber
                --Make lastExpressionWasParenthetical false.
                lastExpressionWasParenthetical = false
            end
        --The following cases deal with the case that we expect an operator instead of an expression.       
        --If the next character is an operator:
        elseif characterPresent(operators, nextCharacter) then
            --Insert the operator into parts.
            table.insert(parts, nextCharacter)
            --Also, update expression by taking out the operator.
            expression = expression:sub(2, #expression)
        --If the next character is a beginning parentheses or the preceding character was an end parentheses and there is a valid number after it, insert a multiplication sign.
        elseif nextCharacter == "(" or (lastExpressionWasParenthetical and nextNumber ~= nil) then table.insert(parts, "*")
        --If the next character is an end parentheses:
        elseif nextCharacter == ")" then
            --If we expect an end parentheses:
            if expectEndParentheses then
                --Take the parentheses out of the expression.
                expression = expression:sub(2, #expression)
                --Set foundEndParentheses to true and exit the while loop.
                foundEndParentheses = true
                break
            --Otherwise, if we were not expecting an end parentheses, then return an error message.
            else return nil, "')' present without matching '(' at '"..nextPiece.."'" end
        --If none of the above cases apply, then the expression must be invalid, so return an error message.
        else return nil, "Expected expression, but found '"..nextPiece.."'" end
        --If we are expecting an expression, switch to expecting an operator and vice versa.
        expectingExpression = not expectingExpression
    end
    --If, at the end, we are left expecting an expression or have not found an end parentheses despite being told we would, then the expression ended before it was supposed to, so return an error message.
    if expectEndParentheses and not foundEndParentheses then return nil, "Expression unexpectedly ended ('(' present without matching ')')" end
    if expectingExpression then return nil, "Expression unexpectedly ended" end
    --Otherwise, the expression has been parsed successfully, so now we must evaulate it.
    --Loop through parts backwards and evaluate the exponentiation operations:
    --Notice that we loop through exponentiation since exponentiation is right-associative (2^3^4=2^81, not 8^4) and that we do not use a for loop since the value of #parts is going to change.
    local i = #parts
    while i >= 1 do
        --If the current part is an exponentiation operator, evaluate the operation, put the result in the slot of the former number, and remove the operator along with the latter number.
        if parts[i] == "^" then
            parts[i-1] = parts[i-1]^parts[i+1]
            table.remove(parts, i+1)
            table.remove(parts, i)
        end
        --Decrement i.
        --Notice that we decrement i regardless of if we have just encountered an exponentiation operator. This is because since we are going backwards, the operator we are on after removing the exponentiation operator must have been ahead of the exponentiation operator in the expression and thus could not have been an exponentiation operator.
        --To understand this better, examine the expression "2^3*4^5". How would this while loop deal with that expression by making sure that all of the exponentiation operations are evaluated?
        i = i-1
    end
    --Loop through parts forwards and evaluate the multiplication and division operators.
    --Notice that we loop forward since division is left-associative (1/2/4=0.5/4, not 1/0.5).
    i = 1
    while i <= #parts do
        --If the current part is a multiplication operator, evaluate the operation, put the result in the slot of the former number, and remove the operator along with the latter number.
        if parts[i] == "*" then
            parts[i-1] = parts[i-1]*parts[i+1]
            table.remove(parts, i+1)
            table.remove(parts, i)
        --If the current part is an division operator, evaluate the operation, put the result in the slot of the former number, and remove the operator along with the latter number.
        elseif parts[i] == "/" then
            parts[i-1] = parts[i-1]/parts[i+1]
            table.remove(parts, i+1)
            table.remove(parts, i)
        --Increment if the current part is not an operator.
        --Notice that we make this incrementation conditional. This is because since we are going backwards, incrementing after we have just processed an operator could make us skip a multiplication or division operator by hopping over it.
        --To understand this better, examine the expression "1/2/3". How does making this incrementation conditional prevent us from skipping over a division operator?
        else i = i+1 end
    end
    --Loop through parts forwards and evaluate the addition and subtraction operators.
    --Notice that we loop forward since subtraction is left-associative (1-2-3=-1-3, not 1-(-1)).
    i = 1
    while i <= #parts do
        --If the current part is an exponentiation operator, evaluate the operation, put the result in the slot of the former number, and remove the operator along with the latter number.
        if parts[i] == "+" then
            parts[i-1] = parts[i-1]+parts[i+1]
            table.remove(parts, i+1)
            table.remove(parts, i)
        --If the current part is an exponentiation operator, evaluate the operation, put the result in the slot of the former number, and remove the operator along with the latter number.
        elseif parts[i] == "-" then
            parts[i-1] = parts[i-1]-parts[i+1]
            table.remove(parts, i+1)
            table.remove(parts, i)
        --Just like with multiplication and division, increment i if the current part is not an operator.
        else i = i+1 end
    end
    --Finally, return the answer (which is in the first element of parts) along with the rest of the expression to be parsed.
    return parts[1], expression
end

--This is an "infinite" while loop which until the program is stopped by the user.
--This way, the program will keep prompting the user to enter expressions until the user stops the program, meaning the user can enter multiple expressions by running the program just once instead of needing to restart the program for each expression.
while true do
    --On the screen, ask the user to enter a mathematical expression:
    io.write("Enter a mathematical expression: ")
    --Read a line from the input and parse the expression that they enter:
    local result, errorMessage = parseExpression(io.read("*line"))
    --If the expression is invalid, then print the error message.
    if result == nil then print(errorMessage)
    --Otherwise, print the result.
    else print(result) end
end
