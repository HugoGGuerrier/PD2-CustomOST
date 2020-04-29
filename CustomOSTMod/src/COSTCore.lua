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
local tracks_dir_path = "mods/CustomOSTTracks/"

if file.DirectoryExists(tracks_dir_path) then
    local tracks_dir = file.GetDirectories(tracks_dir_path)

    for _, dir in pairs(tracks_dir) do

        dir = dir .. "/"

        -- Get the json OR THE FALSE TXT JSON FILE
        local track_json_file = nil
        local track_xml_file = nil
        if file:FileExists(tracks_dir_path .. dir .. "track.txt") then
            track_json_file = tracks_dir_path .. dir .. "track.txt"
        end
        if file:FileExists(tracks_dir_path .. dir .. "track.json") then
            track_json_file = tracks_dir_path .. dir .. "track.json"
        end
        if file:FileExists(tracks_dir_path .. dir .. "main.xml") then
            track_xml_file = tracks_dir_path .. dir .. "main.xml"
        end

        if track_json_file then
            COSTTracks:create_from_json_file(track_json_file, tracks_dir_path .. dir)
        end
        if track_xml_file then
            COSTTracks:create_from_xml_file(track_xml_file, tracks_dir_path .. dir)
        end
        
    end
else
    COSTLogger:dev_log("Tracks directory was not found and created")
    file:MakeDir(tracks_dir_path)
end

-- Tell the developer if the core ended with success
COSTLogger:dev_log("Core ended correctly !")