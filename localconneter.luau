--!optimize 2
--!nolint UnknownGlobal

--[[
    LocalConneter - Decompiler URL Loader for Executors
    
    This module connects the Advanced Decompiler V3 to your executor
    by fetching modules via HTTP request and loading them with loadstring.
    
    Usage:
        local conneter = require(LocalConneter)
        local decompiler = conneter.loadDecompiler()
        print(decompiler(bytecode))
]]

local REQUEST = request or http and http.request or http_request or syn and syn.request

if not REQUEST then
    warn("No supported request function found. Please ensure your executor supports request/http.request/http_request/syn.request")
    return nil
end

local BASE_USER = "KATANASOFT66"
local BASE_BRANCH = "main"
local BASE_REPO = "Advanced-Decompiler-V3"
local BASE_URL = string.format("https://raw.githubusercontent.com/%s/%s/%s/%%s.lua", BASE_USER, BASE_REPO, BASE_BRANCH)

local modules = {
    "Implementations",
    "Reader",
    "Strings",
    "Luau",
    "Base64"
}

local function fetchModule(moduleName)
    local url = string.format(BASE_URL, moduleName)
    
    local success, response = pcall(function()
        return REQUEST({
            Url = url,
            Method = "GET"
        })
    end)
    
    if not success then
        warn(string.format("[%s] Failed to fetch %s: %s", os.date("%H:%M:%S"), moduleName, tostring(response)))
        return nil
    end
    
    if response.StatusCode ~= 200 then
        warn(string.format("[%s] HTTP %d when fetching %s", os.date("%H:%M:%S"), response.StatusCode, moduleName))
        return nil
    end
    
    local body = response.Body or response.body
    
    if not body or #body == 0 then
        warn(string.format("[%s] Empty response for %s", os.date("%H:%M:%S"), moduleName))
        return nil
    end
    
    local loadSuccess, loadedFunc = pcall(loadstring, body)
    
    if not loadSuccess then
        warn(string.format("[%s] Failed to loadstring %s: %s", os.date("%H:%M:%S"), moduleName, tostring(loadedFunc)))
        return nil
    end
    
    if type(loadedFunc) ~= "function" then
        warn(string.format("[%s] loadstring did not return a function for %s (got %s)", os.date("%H:%M:%S"), moduleName, type(loadedFunc)))
        return nil
    end
    
    return loadedFunc()
end

local function loadDecompiler()
    local loadedModules = {}
    
    -- Load all required modules
    for _, moduleName in ipairs(modules) do
        local module = fetchModule(moduleName)
        if not module then
            warn(string.format("[Decompiler] Critical module '%s' failed to load. Decompiler may not work correctly.", moduleName))
        end
        loadedModules[moduleName] = module
    end
    
    -- Check if all critical modules are loaded
    local criticalModules = {"Implementations", "Reader", "Strings", "Luau", "Base64"}
    for _, moduleName in ipairs(criticalModules) do
        if not loadedModules[moduleName] then
            warn("[Decompiler] Missing critical module: " .. moduleName)
            return nil
        end
    end
    
    -- Now load the main init.lua logic
    local initUrl = string.format(BASE_URL, "init")
    
    local success, response = pcall(function()
        return REQUEST({
            Url = initUrl,
            Method = "GET"
        })
    end)
    
    if not success or (response.StatusCode or 0) ~= 200 then
        warn("[Decompiler] Failed to fetch init.lua")
        return nil
    end
    
    local initBody = response.Body or response.body
    
    -- Modify init.lua to use our loaded modules instead of fetching from URL
    local modifiedInit = initBody:gsub(
        "local LoadFromUrl.-end",
        [[
        local LoadFromUrl = function(moduleName)
            return loadedModules[moduleName]
        end
        ]]
    )
    
    -- Inject our loaded modules into the environment
    local env = setmetatable({
        Implementations = loadedModules.Implementations,
        Reader = loadedModules.Reader,
        Strings = loadedModules.Strings,
        Luau = loadedModules.Luau,
        Base64 = loadedModules.Base64,
        loadedModules = loadedModules,
        request = REQUEST,
        http = { request = REQUEST },
        pcall = pcall,
        warn = warn,
        print = print,
        type = type,
        tostring = tostring,
        string = string,
        table = table,
        math = math,
        os = os,
        bit32 = bit32,
        pairs = pairs,
        ipairs = ipairs,
        next = next,
        rawget = rawget,
        rawset = rawset,
        getfenv = getfenv,
        setfenv = setfenv,
        loadstring = loadstring,
        error = error,
        assert = assert,
        select = select,
        unpack = unpack or table.unpack,
        coroutine = coroutine,
        debug = debug,
    }, {
        __index = _G
    })
    
    local loadSuccess, decompilerFunc = pcall(function()
        local func, err = loadstring(modifiedInit)
        if not func then
            error(err)
        end
        setfenv(func, env)
        return func()
    end)
    
    if not loadSuccess then
        warn("[Decompiler] Failed to initialize decompiler: " .. tostring(decompilerFunc))
        return nil
    end
    
    return decompilerFunc
end

return {
    fetchModule = fetchModule,
    loadDecompiler = loadDecompiler,
    modules = modules,
    baseUrl = BASE_URL
}
