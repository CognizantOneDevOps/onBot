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

process.env.NODE_TLS_REJECT_UNAUTHORIZED = "0";
var request = require('request');
var function_call = function (urelease_url, username, password, callback_list_roles) {

var options = {
    url: urelease_url + '/roles/name',
    auth: {
        'user': username,
        'pass': password
    }
};

function callback(error, response, body) {
    if (!error && response.statusCode == 200) {
body = JSON.parse(body);
var len = body.length;
var str = '*ID*\t\t\t*NAME*\t\t\t*RESOURCE*\n';
for(i=0;i<len;i++)
{
str = str + body[i].id+' \t\t '+body[i].name+' \t\t '+body[i].resourceType + '\n';
}
callback_list_roles("null",str,"null");


    }
	else
	{
		callback_list_roles("Error","Error","Error");
	}
}

request(options, callback);
}




module.exports = {
  list_roles: function_call	// MAIN FUNCTION
  
}
