import json
import requests
data = {
 "radioType": "gsm",
 "cellTowers": [
  {
   "cellId": 20102,    "locationAreaCode": 5241,    "mobileCountryCode": 432,    "mobileNetworkCode": 11
  },
  {
   "cellId": 10102,    "locationAreaCode": 5241,    "mobileCountryCode": 432,    "mobileNetworkCode": 11
  },
  {
   "cellId": 20372,    "locationAreaCode": 5241,    "mobileCountryCode": 432,    "mobileNetworkCode": 11
  },
  {
   "cellId": 30243,    "locationAreaCode": 5241,    "mobileCountryCode": 432,    "mobileNetworkCode": 11
  },
  {
   "cellId": 30102,    "locationAreaCode": 5241,    "mobileCountryCode": 432,    "mobileNetworkCode": 11
  },
  {
   "cellId": 20050,    "locationAreaCode": 5241,    "mobileCountryCode": 432,    "mobileNetworkCode": 11
  }
 ]
}


data_json = json.dumps(data)
r = requests.get('https://location.services.mozilla.com/v1/geolocate?key=test', data = data_json)
print r.content

