function vd_string(o)
    return '"' .. tostring(o) .. '"'
end


function vd_recurse(o, indent)
    if indent == nil then indent = '' end
    local indent2 = indent .. '  '
    if type(o) == 'table' then
        local s = indent .. '{' .. '\n'
        local first = true
        for k, v in pairs(o) do
            if first == false then s = s .. ', \n' end
            if type(k) ~= 'number' then k = vd_string(k) end
            s = s .. indent2 .. '[' .. k .. '] = ' .. vd_recurse(v, indent2)
            first = false
        end
        return s .. '\n' .. indent .. '}'
    else
        return vd_string(o)
    end
end

function var_dump(...)
    local args = { ... }
    if #args > 1 then
        var_dump(args)
    else
        ngx.say(vd_recurse(args[1]))
    end
end

function is_identity(n)
    -- todo 32 битное целое
    if tonumber(n) ~= nil then
        return true
    end;

    return false
end

function isEmptyString(s)
    return s == nil or s == ''
end

function isEmptyArray(arr)
    return next(arr) == nil
end
