ipk_build = false
app_root = "/bcap"

if ipk_build then
  app_root = "/opt/opkg/bcap"
end

-- sub-second sleep function; parameter is in ticks of 50ms
function sleep(s)
  local ntime = os.clock() + s/20
  repeat until os.clock() > ntime
end

function header(status, len)
  if status then
    uhttpd.send("Status: " .. status .. "\r\n")
  end
  uhttpd.send("Content-type: text/json; charset=UTF-8\r\n")
  uhttpd.send("Cache-Control: private,max-age=0\r\n")
  uhttpd.send("Access-Control-Allow-Origin: *\r\n")
  if len then
    uhttpd.send("Content-Length: " .. tostring(len) .. "\r\n")
  end
  uhttpd.send("Pragma: no-cache\r\n\r\n")
end

function process_output(file)
  local output = file:read('*l')
  local outputString = ""
  while output do
    outputString = outputString .. string.format("%s\n", output)
    -- uhttpd.send(string.format('%s\n', output))
    output = file:read('*l')
  end
  file:close()

  return outputString
end

function run_pcap(duration)
  -- tcpdump -w dump.pcap -G 30 -W 1
  local params = "start " .. app_root .. '/data/ ' .. os.time() .. ' ' .. duration
  local file = io.popen('HOME=' .. _G['app_root'] .. ' ' .. _G['app_root'] .. '/bin/bcap ' .. params, 'r')
  local output = process_output(file)
  header("200 OK", string.len(output))
  uhttpd.send(output)
end

function check_status()
  local params = "status " .. app_root .. '/data/'
  local file = io.popen('HOME=' .. _G['app_root'] .. ' ' .. _G['app_root'] .. '/bin/bcap ' .. params, 'r')
  local output = process_output(file)
  header("200 OK", string.len(output))
  uhttpd.send(output)
end  

function cancel()
  local params = "cancel " .. app_root .. '/data/'
  local file = io.popen('HOME=' .. _G['app_root'] .. ' ' .. _G['app_root'] .. '/bin/bcap ' .. params, 'r')
  local output = process_output(file)
  header("200 OK", string.len(output))
  uhttpd.send(output)
end

function echo_ts() 
  header("200 OK")
  uhttpd.send(os.time())
end  

local function starts_with(str, start)
  return str:sub(1, #start) == start
end

function handle_request(env)
  path_info = env.REQUEST_URI
  if path_info then
    if starts_with(path_info, "/api/start") then
      run_pcap(path_info:gsub("/api/start/", ""))
    elseif path_info == "/api/status" then
      check_status()
    elseif path_info == "/api/cancel" then
      cancel()
    elseif path_info == "/api/canned" then
      run_pcap_canned()
    elseif path_info == '/api/ts' then
      echo_ts()
    end
  else
    header("404 Not Found")
    print ':)'
  end
end
