plugin = {
    name = "Apache Maven Manager",
    version = "1.0.0",
    author = "OpenCode",
    description = "Maven plugin with Java and Maven prerequisites via sys"
}

local function trim(value)
    return (value:gsub("^%s+", ""):gsub("%s+$", ""))
end

local function command_exists(name)
    local handle = io.popen("command -v " .. name .. " 2>/dev/null")
    if handle == nil then
        return false
    end

    local result = handle:read("*a") or ""
    handle:close()
    return trim(result) ~= ""
end

local function shell_quote(value)
    return "'" .. tostring(value):gsub("'", "'\\''") .. "'"
end

local function sys_call(cmd)
    print("[Maven-Exec] " .. cmd)
    local success = os.execute(cmd)
    return success == true or success == 0
end

local function package_spec(pkg)
    if pkg.version == nil or pkg.version == "" then
        return pkg.name
    end

    return pkg.name .. ":" .. pkg.version
end

function plugin.init()
    if not command_exists("java") then
        print("[Lua: Maven] Fehler: java wurde nicht gefunden.")
        return false
    end

    if not command_exists("mvn") then
        print("[Lua: Maven] Fehler: mvn wurde nicht gefunden.")
        return false
    end

    return true
end

function plugin.getCategories()
    return { "Java", "Build", "Maven" }
end

function plugin.getRequirements()
    return {
        { system = "sys", name = "java-21-openjdk-devel" },
        { system = "sys", name = "maven" }
    }
end

function plugin.install(packages)
    if #packages == 0 then return true end

    local targets = {}
    for _, pkg in ipairs(packages) do
        table.insert(targets, shell_quote(package_spec(pkg)))
    end

    return sys_call("mvn dependency:get -Dtransitive=true " .. table.concat(targets, " "))
end

function plugin.remove(packages)
    if #packages == 0 then return true end

    local targets = {}
    for _, pkg in ipairs(packages) do
        table.insert(targets, shell_quote(package_spec(pkg)))
    end

    return sys_call("mvn dependency:purge-local-repository -DmanualInclude=" .. table.concat(targets, ","))
end

function plugin.search(prompt)
    return {
        {
            name = prompt,
            version = "unknown",
            description = "Maven artifact lookup is not implemented yet"
        }
    }
end

function plugin.update(packages)
    if #packages == 0 then
        return true
    end

    return plugin.install(packages)
end

function plugin.list()
    return {}
end

function plugin.shutdown()
    return true
end

function plugin.info(name)
    return {
        name = name,
        version = "unknown",
        description = "Maven artifact"
    }
end
