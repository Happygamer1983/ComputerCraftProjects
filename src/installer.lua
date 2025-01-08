local args = {...}
local libraries = {UIFunctions = "https://raw.githubusercontent.com/Happygamer1983/ComputerCraftProjects/refs/heads/main/src/UIFunctions.lua"}
local TESTlibraries = {UIFunctions = "https://raw.githubusercontent.com/Happygamer1983/ComputerCraftProjects/refs/heads/main/src/CCTest.lua"}

fs.makeDir("lib")

if args[1] == "Test" then
    for LibName, LibURL in pairs(TESTlibraries) do
        local lib = http.get(LibURL)
        local libcode = lib.readAll()
        local libfile = fs.open("lib/" .. LibName, "w")
        libfile.write(libcode)
        libfile.close()
        require("lib/" .. LibName)
    end
end
