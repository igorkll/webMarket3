local component_invoke, eeprom_address = component.invoke, component.list("eeprom")()

component.invoke = function(address, name, ...)
    checkArg(1, address, "string")
    checkArg(2, name, "string")
    if address == eeprom_address then
        if name == "set" then
            return nil, "storage is readonly"
        end
        return component_invoke(address, name, ...)
    else
        return component_invoke(address, name, ...)
    end
end
internetBoot("https://raw.githubusercontent.com/IgorTimofeev/MineOS/master/Installer/Main.lua")