-- Load all mod files
local source_dir_path = ModPath .. "src/"

if file.DirectoryExists(source_dir_path) then
    local source_files = file.GetFiles(source_dir_path)

    for _, file in pairs(source_files) do
        if file ~= "COSTCore.lua" and file ~= "COSTHooks.lua" then
            dofile(source_dir_path .. file)
        end
    end
else
    log("[CustomOST] [Error] : Cannot find the source directory, please reinstall this mod")
end

-- Verify and start the x audio
if not XAudio then
    COSTLogger:log_err("You need XAudio to make this mod work")
    return
end

blt.xaudio.setup()

-- Load all custom tracks
local tracks_dir_path = "mods/CustomTracks/"

if file.DirectoryExists(tracks_dir_path) then
    local tracks_dir = file.GetDirectories(tracks_dir_path)

    for _, dir in pairs(tracks_dir) do

        dir = dir .. "/"
        local track_json_file = tracks_dir_path .. dir .. "track.json"
        COSTTracks:create_from_file(track_json_file, tracks_dir_path .. dir)
        
    end
else
    COSTLogger:dev_log("Tracks directory was not found and created")
    file:MakeDir(tracks_dir_path)
end

-- Tell the developer if the core ended with success
COSTLogger:dev_log("Core ended correctly !")