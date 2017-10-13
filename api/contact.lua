local ecode = require "common.ErrCode"
local common = require "common.common"
local constants = require "common.constants"
local mysqlCon = require "common.mysqlcon"
local redisCon = require "common.rediscon"
local cjson = require "cjson" 

--初始化MYSQL 
local db, err = mysqlCon:init_mysql()
if not db then 
    common.write_resp(err);
    return  
end

--初始化REDIS 
local redis, err = redisCon.init_redis()
if not redis then
    common.write_resp(err)
    return  
end

--参数解析
local args = common.get_args()
--[[
if args["name"] == nil or args["email"] == nil then
    common.write_resp(ecode.ARGS_ERR)
    return  
end
]]--

ngx.log(ngx.DEBUG, args)
local quoted_name
if args["name"] then
    quoted_name = ngx.quote_sql_str(args["name"])
end
local quoted_email
if args["email"] then
    quoted_email = ngx.quote_sql_str(args["email"])
end
local quoted_subject
if args["subject"] then
    quoted_subject = ngx.quote_sql_str(args["subject"])
end
local quoted_message
if args["message"] then
    quoted_message = ngx.quote_sql_str(args["message"])
end

-- @function: 存储反馈
-- @return: ecode
function set_contact(name, email, subject, message)
    local sql = "INSERT INTO contact(name, email, subject, message) VALUES(" --..name..", "..email..", "..subject..", "..message..")"
    if not name then
        sql = sql.."NULL, "
    else
        sql = sql..name..", "
    end
    if not email then
        sql = sql.."NULL, "
    else
        sql = sql..email..", "
    end 
    if not subject then
        sql = sql.."NULL, "
    else
        sql = sql..subject..", "
    end 
    if not message then
        sql = sql.."NULL)"
    else
        sql = sql..message..")"
    end 
    ngx.log(ngx.DEBUG, "存储反馈信息SQL:", sql)
    local res, err, errno, sqlstate = db:query(sql)
    if not res then
        ngx.log(ngx.ERR, "bad result: ", err, ": ", errno, ": ", sqlstate, ".")
        return ecode.DB_ERR
    end
    if next(res) == nil then
        return ecode.SYS_ERR
    end
    return ecode.OK
end

local err = set_contact(quoted_name, quoted_email, quoted_subject, quoted_message)
if err ~= ecode.OK then
    return common.write_resp(err)
end
common.write_resp(ecode.OK, resp_data)


