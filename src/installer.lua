local args = {...}

local VersionURL = "https://raw.githubusercontent.com/Happygamer1983/ComputerCraftProjects/refs/heads/main/src/VERSION"

local libraries = {
    main = "https://raw.githubusercontent.com/Happygamer1983/ComputerCraftProjects/refs/heads/main/src/main.lua",
    UIFunctions = "https://raw.githubusercontent.com/Happygamer1983/ComputerCraftProjects/refs/heads/main/src/UIFunctions.lua"
}
local TESTlibraries = {UIFunctions = "https://raw.githubusercontent.com/Happygamer1983/ComputerCraftProjects/refs/heads/main/src/CCTest.lua"}

if fs.exists("lib") then
    fs.delete("lib")
end

fs.makeDir("lib")

if args then
    if string.lower(args[1]) == "test" then
        for LibName, LibURL in pairs(TESTlibraries) do
            local lib = http.get(LibURL)
            local libcode = lib.readAll()
            local libfile = fs.open("lib/" .. LibName, "w")
            libfile.write(libcode)
            libfile.close()
            require("lib/" .. LibName)
        end
    end
else
    for LibName, LibURL in pairs(libraries) do
        local lib = http.get(LibURL)
        local libcode = lib.readAll()
        local libfile = fs.open("lib/" .. LibName, "w")
        libfile.write(libcode)
        libfile.close()
    end
    local VersionFile = fs.open("VERSION", "w")
    VersionFile.write(http.get(VersionURL).readAll())
    VersionFile.close()
    print("Install complete, to start program type:")
	print("'cd lib/' then 'main'")
end
