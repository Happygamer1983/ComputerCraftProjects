local args = {...} or {}
local libraries = {
    main = "https://raw.githubusercontent.com/Happygamer1983/ComputerCraftProjects/refs/heads/main/src/main.lua",
    UIFunctions = "https://raw.githubusercontent.com/Happygamer1983/ComputerCraftProjects/refs/heads/main/src/UIFunctions.lua"
}
local TESTlibraries = {UIFunctions = "https://raw.githubusercontent.com/Happygamer1983/ComputerCraftProjects/refs/heads/main/src/CCTest.lua"}

fs.makeDir("lib")

if string.lower(args[1]) == "test" then
    for LibName, LibURL in pairs(TESTlibraries) do
        local lib = http.get(LibURL)
        local libcode = lib.readAll()
        local libfile = fs.open("lib/" .. LibName, "w")
        libfile.write(libcode)
        libfile.close()
        require("lib/" .. LibName)
    end
elseif string.lower(args[1]) == "nil" then
    for LibName, LibURL in pairs(libraries) do
        local lib = http.get(LibURL)
        local libcode = lib.readAll()
        local libfile = fs.open("lib/" .. LibName, "w")
        libfile.write(libcode)
        libfile.close()
    end
    require("lib/main")
end
