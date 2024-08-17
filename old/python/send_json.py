import json
import requests
data = {
 "radioType": "gsm",
 "cellTowers": [
  {
   "cellId": 15796032,    "locationAreaCode": 30241,    "mobileCountryCode": 432,    "mobileNetworkCode": 11
  }
 ]
}


data_json = json.dumps(data)
r = requests.get('https://location.services.mozilla.com/v1/geolocate?key=test', data = data_json)
print r.content

