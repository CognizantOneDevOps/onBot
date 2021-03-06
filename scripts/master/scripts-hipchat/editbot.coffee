#-------------------------------------------------------------------------------
# Copyright 2018 Cognizant Technology Solutions
# 
# Licensed under the Apache License, Version 2.0 (the "License"); you may not
# use this file except in compliance with the License.  You may obtain a copy
# of the License at
# 
#   http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.  See the
# License for the specific language governing permissions and limitations under
# the License.
#-------------------------------------------------------------------------------

###
Description:
 OneDevOps-OnBots Editbot functionality implementation for hubot

Configurations:
 MATTERMOST_URL: your mattermost server url
 ONBOTS_URL: your OneDevOps-OnBots server url

Commands:
 @botname get details for <mongodb_objectId_of_the_bot> -> shows details of the bot along with json template required to redeploy it
 @botname redeploy <mongodb_objectId_of_the_bot> with config <mattermost_file_id_of_user's_jsonfile> -> redeploys bot with the given json file data and updates the
 changes in mongodb
###

fs = require('fs') # Requiring npm file-system package

request = require('request') # Requiring npm request package

process.env.NODE_TLS_REJECT_UNAUTHORIZED = "0";

module.exports = (robot) ->
	robot.respond /getBotDetails (.*)/i, (msg) ->
		botname = msg.match[1]
		options = {
			url: process.env.ONBOTS_URL+"/newbot/"+botname,
			method: "GET"
		}
		request.get options, (error, response, body) ->
			if typeof(body)!="object" && body.indexOf("error")==-1
				jsonbody = JSON.parse(body)
				dt = "Name"+"	||	"+"Value\n"
				dt += "=============================\n"
				dt += "BotName"+"	||	"+jsonbody.BotName+"\nBot description"+"	||	"+jsonbody.BotDesc+"\nBot Type"+"	||	"+jsonbody.bots+"\n"
				dt +="Adapter"+"	||	"+jsonbody.adapter+"\nBot Status"+"	||	"+jsonbody.status+"\n"
				if jsonbody.adapter=='slack'
					dt += "Slack Token"+"	||	"+jsonbody.slack+"\n\nConfigurations"
				else if jsonbody.adapter=='mattermost'
					dt += "Mattermost Incoming Url"+"	||	"+jsonbody.MatterInURL+"\nMattermost Outgoing Token"+"	||	"+jsonbody.Matter+"\n\nConfigurations"
				else
					dt += "Hipchat User ID"+"	||	"+jsonbody.hipchatId+"\nHipchat Password"+"	||	XXXXXX\n\nConfigurations"
				for i in [0...jsonbody.configuration.length]
					if jsonbody.configuration[i].type=='password'
						dt += "\n"+jsonbody.configuration[i].key+"	||	XXXXXX"
					else
						dt += "\n"+jsonbody.configuration[i].key+"	||	"+jsonbody.configuration[i].value
				msg.send dt
				dt = "JSON template for editing bot: "+botname+"\n"
				dt += "{\"BotName\":\""+jsonbody.BotName+"\",\"type\":\""+jsonbody.bots+"\",\"repo\":\""+jsonbody.repo+"\",\"BotDesc\":\""+jsonbody.BotDesc+"\",\"id\":\""+jsonbody._id+"\",\n\"configuration\":["
				for i in [0...jsonbody.configuration.length]
					if i==jsonbody.configuration.length-1
						dt += "{\"key\":\""+jsonbody.configuration[i].key+"\",\"type\":\""+jsonbody.configuration[i].type+"\",\"bot_env\":\""+jsonbody.configuration[i].bot_env+"\",\"value\":\""+jsonbody.configuration[i].value+"\"}]"
					else
						dt += "{\"key\":\""+jsonbody.configuration[i].key+"\",\"type\":\""+jsonbody.configuration[i].type+"\",\"bot_env\":\""+jsonbody.configuration[i].bot_env+"\",\"value\":\""+jsonbody.configuration[i].value+"\"},"
				if jsonbody.bots=="User Defined Bot"
					dt += ",\"addToExtJson\":\""+jsonbody.addToExtJson+"\""
				dt += ",\"adapter\":\""+jsonbody.adapter+"\""
				if jsonbody.adapter=='slack'
					dt += ",\"slack\":\""+jsonbody.slack+"\"}"
				else if jsonbody.adapter=='mattermost'
					dt += ",\"MatterInURL\":\""+jsonbody.MatterInURL+"\",\"Matter\":\""+jsonbody.Matter+"\"}"
				else
					dt += ",\"hipchatId\":\""+jsonbody.hipchatId+"\",\"hipchatPassword\":\""+jsonbody.hipchatPassword+"\"}"
				msg.send dt
			else
				msg.send "Bot doesn't exist"
	
	robot.respond /editbot (.*) (.*) (.*) (.*)/i, (msg) ->
		botname = msg.match[1]
		fileid = msg.match[2]
		filename = msg.match[3]
		jidinitial = msg.match[4].split("_")[0]
		jid = msg.match[4].split("_")[1].split("@")[0]
		console.log(filename)
		dbbot = {}
		dbbotopt = {
			url: process.env.ONBOTS_URL+"/newbot/"+botname,
			method: "GET"
		}
		request.get dbbotopt, (error, response, body) ->
			dbbot = JSON.parse(body)
			options = {
				url : "https://s3.amazonaws.com/uploads.hipchat.com/"+jidinitial+"/"+jid+"/"+fileid+"/"+filename,
				method: "GET"
			}

			request.get options, (error, response, body) ->
				console.log(body)
				jsonbody = JSON.parse(body)
				console.log(jsonbody)
				for i in [0...dbbot.configuration.length]
					dbbot.configuration[i].value = jsonbody.configuration[i].value
				if jsonbody.adapter=='slack'
					dbbot["slack"]=jsonbody.slack
					dbbot["hipchatId"]=''
					dbbot["hipchatPassword"]=''
					dbbot["Matter"]=''
					dbbot["MatterInURL"]=''
				else if jsonbody.adapter=='hipchat'
					dbbot["hipchatId"]=jsonbody.hipchatId
					dbbot["hipchatPassword"]=jsonbody.hipchatPassword
					dbbot["slack"]=''
					dbbot["Matter"]=''
					dbbot["MatterInURL"]=''
				else
					dbbot["Matter"]=jsonbody.Matter
					dbbot["MatterInURL"]=jsonbody.MatterInURL
					dbbot["slack"]=''
					dbbot["hipchatId"]=''
					dbbot["hipchatPassword"]=''
				mongodata = {
					url: process.env.ONBOTS_URL+"/newbot/"+botname,
					method: "PUT",
					headers: {"Content-type":"application/json"},
					body: dbbot,
					json: true
				}
				#updating user's bot data to mongodb
				request.put mongodata, (err, res, body) ->
					if body==undefined
						console.log err
						msg.send "Couldn't modify your changes in mongodb. Refer to hubot.log file for more details."
					else
						console.log(body)
						msg.send "Updated bot details successfully. Please restart the bot to apply the changes."
	
	robot.respond /restart (.*)/i, (msg) ->
		botname = msg.match[1]
		msg.send "Restarting "+botname+"...."
		botobj = {}
		dbbot = {}
		botopt = {
			url: process.env.ONBOTS_URL+"/newbot/"+botname,
			method: "GET"
		}
		#getting bot object from mongodb
		request.get botopt, (error, response, body) ->
			console.log body
			if body.indexOf('error')==-1
				dbbot = JSON.parse(body)
				#assigning values to botobject
				botobj["BotName"]=dbbot.BotName
				botobj["type"]=dbbot.bots
				botobj["repo"]=dbbot.repo
				botobj["adapter"]=dbbot.adapter
				botobj["BotDesc"]=dbbot.BotDesc
				botobj["BotType"]=dbbot.BotType
				botobj["vars"]=[]
				for i in [0...dbbot.configuration.length]
					botobj["vars"][i]=dbbot.configuration[i].bot_env+"="+dbbot.configuration[i].value
				if botobj["adapter"]=='slack'
					botobj["slack"]=dbbot.slack
					botobj["hipchatId"]=''
					botobj["hipchatPassword"]=''
					botobj["Matter"]=''
					botobj["MatterInURL"]=''
				else if botobj["adapter"]=='hipchat'
					botobj["hipchatId"]=dbbot.hipchatId
					botobj["hipchatPassword"]=dbbot.hipchatPassword
					botobj["slack"]=''
					botobj["Matter"]=''
					botobj["MatterInURL"]=''
				else
					botobj["Matter"]=dbbot.Matter
					botobj["MatterInURL"]=dbbot.MatterInURL
					botobj["slack"]=''
					botobj["hipchatId"]=''
					botobj["hipchatPassword"]=''
				if botobj["type"]=="User Defined Bot"
					botobj["addToExtJson"]=dbbot.addToExtJson
				opt = {
					url: process.env.ONBOTS_URL+"/restartbot",
					method: "POST",
					headers: {"Content-type":"application/json"},
					body: botobj,
					json: true
				}
				#restarting bot
				request.post opt, (err, res, body) ->
					console.log "err: "+err
					if body=="Error in Resarting Hubot"
						msg.send "There has been an error while deploying the bot. You may look at the logs for more details."
					else
						msg.send "The bot "+botobj.BotName+" has been redeployed successfully with your changes."
						deletescript = {
							url: process.env.ONBOTS_URL+"/deletefiles/restart"+botobj.BotName+".sh",
							method: "GET"
						}
						#deleting the restartscript created locally inside OnBots server
						request.get deletescript, (err, res, body) ->
							if res.body != 'successfully deleted'
								msg.send "**Warning**: Unable to delete the script file. Refer bot logs for details"
							console.log err
						dbbot["status"]='on'
						mongodata = {
							url: process.env.ONBOTS_URL+"/newbot/"+botname,
							method: "PUT",
							headers: {"Content-type":"application/json"},
							body: dbbot,
							json: true
						}
						#updatingbot status to mongodb
						request.put mongodata, (err, res, body) ->
							if body==undefined
								console.log err
								console.log "Couldn't modify bot status in mongodb. Refer to logs file for more details."
							else
								console.info "Updated bot status in db successfully."
			else
				msg.send body
	
