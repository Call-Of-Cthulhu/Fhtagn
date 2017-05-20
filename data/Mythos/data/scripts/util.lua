function string.split(s, pattern)
    if pattern ~= nil then
        s = string.gsub(s, pattern, " ")
    end
    return string.gmatch(s, "%S+")
end

function table.easytable(mt)
    local t = {}
    mt = mt or {}
    mt.__index = function(t, k)
        local v = {}
        setmetatable(v, mt)
        t[k] = v
        return v
    end,
    setmetatable(t, mt)
    return t
end

function io.scanf(fmt)
    local buf = io.stdin:read('l')
    -- optimazition for single match
    if      fmt == "%s" then
        return tostring(buf)
    elseif  fmt == "%i" or fmt == "%d" then
        return buf and tonumber(buf)
    end
    local res = {}
    fmt = string.gsub(fmt, "%%s", "(%%w+)")
    fmt = string.gsub(fmt, "%%i", "(%%d+)")
    fmt = string.gsub(fmt, "%%%%", "%%")
    local itr = string.gmatch(buf, fmt)
    for i = 1, 1000 do -- arbitrary number to avoid dead loop
        local t = table.pack(itr())
        if #t <= 0 then
            break
        end
        for _, v in ipairs(t) do
            table.insert(res, v)
        end
    end
    return table.unpack(res)
end

function io.printf(fmt, ...)
    return io.stdout:write(string.format(fmt, ...))
end

function eval(s, name, mode, env)
    if s == nil then return nil end
    local chunk = load(s, name, mode, env)
    if chunk == nil then
        error("Function 'load' returns nil!")
    end
    if type(chunk) ~= "function" then
        error("Function 'load' returns invalid chunk("..type(chunk)..")!")
    end
    return chunk()
end

function string.getBytes(s, bytes)
    local ftlen = 0
    for uchar in string.gmatch(s, "[%z\1-\127\194-\244][\128-\191]*") do
        if bytes ~= nil then
            table.insert(bytes, uchar)
        end
        --print(uchar, #uchar)
        if #uchar > 1 then
            ftlen = ftlen + 2
        else
            ftlen = ftlen + 1
        end
    end
    return ftlen
end

function string.strlen(s)
    local _, count = string.gsub(s, "[^\128-\193]", "")
    return count
end
