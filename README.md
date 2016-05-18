## Sensu-Plugins-plivo

## Functionality

## Files
 * bin/handler-plivosms.rb

## Usage

```
{
  "plivosms":{
    "id":"AC0ds98gd098g",               // auth id
    "token":"a9d8ag98daf98ga9fd8g",     // auth token
    "number":"15551112222",             // the sms will be sent from this number, include country code
    "recipients":{
      "15552223333": {
        "subscriptions":[ "web" ],      // subscriptions that should trigger sms
        "checks":[],                    // checks that should trigger sms
        "cutoff": 1                     // 1 for warning, 2 for critical alerts (default is 2)
      },
      "11111222222": {
        "subscriptions":[ 'all' ],        // 'all' 
        "checks":[ "mysql-alive" ],
        "cutoff": 2
      },
      "11111223333": {                    // not specifying "subscriptions" is same as 'all'
        "checks":[ "check_dns", "check_http" ]
      },
      "11111224444": {                    
        "cutoff": 1                       // "subscriptions" and "checks" are optional, defaults 'all'
      }
    }
  }
}

Example Sensu Core Integration
/etc/sensu/conf.d/plivosms_handler.json
{
  "handlers": {
    "plivosms": {
      "type": "pipe",
      "command": "/opt/sensu/embedded/bin/handler-plivosms.rb"
    }
  },
  "plivosms":{
    "id":"098gf09d8fg",                   // auth id
    "token":"a9d8ag98daf98ga9fd8g",       // auth token
    "number":"15551112222",               // the sms will be sent from this number, include country code
    "recipients":{
      
      "11111223333": {                    // not specifying "subscriptions" is same as 'all'
        "checks":[ "check_dns", "check_http" ]
      },
      "11111224444": {                    
        "cutoff": 1                       // this guys gets all alerts including warnings
      }
    }
  }
}

If you want to make Plivosms a default handler, meaning any check without a specific handler defined will notify Plivosms when there is an alert, open the default handler configuration file and add Plivosms to the set of handlers:

/etc/sensu/conf.d/default_handler.json
{
  "handlers": {
    "default": {
      "type": "set",
      "handlers": [
        "plivosms"
      ]
    }
  }
}

Restart Sensu for your configuration changes to take effect: service sensu-server restart

```
## Installation

[Installation and Setup](http://sensu-plugins.io/docs/installation_instructions.html)

## Notes
