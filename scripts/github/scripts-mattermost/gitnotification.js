/*******************************************************************************
*Copyright 2018 Cognizant Technology Solutions
* 
* Licensed under the Apache License, Version 2.0 (the "License"); you may not
* use this file except in compliance with the License.  You may obtain a copy
* of the License at
* 
*   http://www.apache.org/licenses/LICENSE-2.0
* 
* Unless required by applicable law or agreed to in writing, software
* distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
* WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.  See the
* License for the specific language governing permissions and limitations under
* the License.
 ******************************************************************************/

var request = require("request");
var now = require("date-now")

var function_call = function (git_repo, flag, clear_id, callback_git_notify) {

var git_repo = git_repo;
var user_name = process.env.HUBOT_GITHUB_USER;
var api_token = process.env.HUBOT_GITHUB_TOKEN;







	var datetime = new Date();
	var old_commit_id = '';
  var options = { method: 'GET',
  url: 'http://api.github.com/repos/'+user_name+'/'+git_repo+'/commits',
  headers: 
   { 'user-agent': 'node.js',
   'authorization': 'token '+api_token
   } };

request(options, function (error, response, body) {
  if (!error && response.statusCode==200){

  body = JSON.parse(body);
  var length = body.length;
for(i = 0; i< length / 2; i++)
{
	var date = body[i].commit.author.date;
	 var str_date = new Date(date);
 var diff = datetime.getTime() - str_date.getTime();
  diff = (diff / 1000);
    if(diff < 6 && diff > 0)
  {
	  var final_str = 'Commited in '+git_repo+' with commit-ID : '+body[i].sha+', Commit-author-name : '+body[i].commit.author.name+', time : '+body[i].commit.author.date;
	  console.log('INFO: Notified commit details');
	  callback_git_notify(null,final_str,null);
  }
  else
  {
	  callback_git_notify("notifyerror","notifyerror","notifyerror");
  }
}

  
  }

 
});

}
module.exports = {
 git_notify: function_call	// MAIN FUNCTION
  
}
