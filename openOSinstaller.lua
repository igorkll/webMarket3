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

local function segments(path)
    local parts = {}
    for part in path:gmatch("[^\\/]+") do
        local current, up = part:find("^%.?%.$")
        if current then
            if up == 2 then
                table.remove(parts)
            end
        else
            table.insert(parts, part)
        end
    end
    return parts
end

local function fs_path(path)
    local parts = segments(path)
    local result = table.concat(parts, "/", 1, #parts - 1) .. "/"
    if unicode.sub(path, 1, 1) == "/" and unicode.sub(result, 1, 1) ~= "/" then
        return "/" .. result
    else
        return result
    end
end

local function saveFile(fs, path, data)
    fs.makeDirectory(fs_path(path))
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
            status("Saving File: " .. filePath, -1)
            local ok, err = saveFile(component.proxy(address), filePath, file)
            if ok then
                status("Saved File: " .. filePath, -1)
            else
                status("Error To Save File: " .. (err or "Unkown"), -1)
            end
        else
            status("Error To Get File: " .. (err or "Unkown"), -1)
        end
    end
end

local function selectBranch()
    local branchs = {"Main", "Dev", "Back"}
    local num = menu("Select Branch", branchs)
    if num == #branchs then return nil end
    return branchs[num]:lower()
end

while true do
    local selected = selectfs("Select Fs To Install")
    if not selected then return end

    local fs = component.proxy(selected)
    local label = fs.getLabel()
    if fs.isReadOnly() then
        status("Filesystem Is Readonly", true)
    else
        local modes = {"OpenOS Classic", "OpenOS Modified", "Mod Only(No Os)", "Back"}
        local num = menu("Select Distribution", modes)
        if num ~= 4 and yesno("Install " .. modes[num] .. " To " .. ((label and (label .. "-") or "") .. selected:sub(1, 3)) .. "?") then
            if yesno("Format?") then fs.remove("/") end
            if num == 1 then
                install(selected, "https://raw.githubusercontent.com/igorkll/openOS/main")
            elseif num == 2 then
                local branch = selectBranch()
                if not branch then return end
                install(selected, "https://raw.githubusercontent.com/igorkll/openOS/main")
                install(selected, "https://raw.githubusercontent.com/igorkll/openOSpath/" .. branch)
            elseif num == 3 then
                local branch = selectBranch()
                if not branch then return end
                install(selected, "https://raw.githubusercontent.com/igorkll/openOSpath/" .. branch)
            end
        end
    end
end
