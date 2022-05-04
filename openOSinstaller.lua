local function selectfs(label)
    local data = {n = {}, a = {}}
    for address in component.list("filesystem") do
        if not component.invoke(address, "isReadOnly") then
            data.n[#data.n + 1] = fsName(address)
            data.a[#data.a + 1] = address
        end
    end
    table.insert(data.n, "Back")

    local select = menu(label, data.n)
    local address = data.a[select]
    return address
end

local function saveFile(fs, path, data)
    local file, err = fs.open(path, "wb")
    if not file then return nil, err end
    fs.write(file, data)
    fs.close(file)
    return true
end

local function install(address, url)
    local filelist = getInternetFile(url .. "/filelist.txt")
    filelist = split(filelist, "\n")

    for i, filePath in ipairs(filelist) do
        local fileUrl = url .. filePath
        local file, err = getInternetFile(fileUrl)
        if file then
            status("saving file: " .. filePath)
            local ok, err = saveFile(component.proxy(address), filePath, file)
            if ok then
                status("saved file: " .. filePath)
            else
                status("error to save file: " .. (err or "unkown"))
            end
        else
            status("error to get file: " .. (err or "unkown"))
        end
    end
end

while true do
    local selected = selectfs("select fs to install")
    if not selected then return end

    local fs = component.proxy(selected)
    local label = fs.getLabel()
    if fs.isReadOnly() then
        status("filesystem is readonly", true)
    else
        local modes = {"openOS classic", "openOS modified", "mod only(no os)", "back"}
        local num = menu("select distribution", modes)
        if num ~= 4 and yesno("install " .. modes[num] .. " to " .. ((label and (label .. "-") or "") .. selected:sub(1, 3)) .. "?") then
            if yesno("format?") then fs.remove("/") end
            if num == 1 then
                install(selected, "https://raw.githubusercontent.com/igorkll/openOS/main")
            elseif num == 2 then
                install(selected, "https://raw.githubusercontent.com/igorkll/openOS/main")
                install(selected, "https://raw.githubusercontent.com/igorkll/openOSpath/main")
            elseif num == 3 then
                install(selected, "https://raw.githubusercontent.com/igorkll/openOSpath/main")
            end
        end
    end
end