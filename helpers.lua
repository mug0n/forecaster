function string.getCharPos(str, charCode)
    for i = 1, string.len(str), 1 do
        if string.byte(str, i) == charCode then
            return i
        end
    end
    return nil
end

function table.contains(table, element)
    for _, value in pairs(table) do
        if value == element then
            return true
        end
    end
    return false
end