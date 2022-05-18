import requests
import json
from pandas.io.json import json_normalize
import pandas as pd
from datetime import datetime, timedelta


def api():
  today = datetime.today()
  yesterday = today - timedelta(days=1)
  today_format = today.strftime("%Y-%m-%d")
  yesterday_format = yesterday.strftime("%m-%d-%Y")
  
  symbol_id = 'BITSTAMP_SPOT_BTC_USD'
  period_id = '1MIN'
  time_start = yesterday_format
  time_end = today_format
  limit = '5000'
  
  url = 'https://rest.coinapi.io/v1/ohlcv/{}/history?period_id={}&time_start={}&time_end={}&limit={}'.format(symbol_id, period_id, time_start, time_end, limit)
        
  cryp_headers = {
    #'Accept': 'application/json',
    'X-CoinAPI-Key': 'EC375679-F70B-4353-B2EC-93B89BC9C519',
  } 
  
  resp = r.get(url, headers = cryp_headers).json()
  
  return resp



def upload_blob(data, bucket_name, target_file_name):
    from google.cloud import storage
    "Uploads a file to the bucket."
    storage_client = storage.Client()
    bucket = storage_client.get_bucket(bucket_name)
        
    local_file_name = "/tmp/data.csv"
    data.to_csv(local_file_name, index=False)
    #with open(local_file_name, "w") as csv :
     #   csv.write(data.to_string())

    cloud_file_blob = bucket.blob(target_file_name)
    cloud_file_blob.upload_from_filename(local_file_name)


    print('File {} uploaded to {}.'.format(target_file_name, bucket_name))


def download_data(request):
    """Responds to any HTTP request.
    Args:
        request (flask.Request): HTTP request object.
    Returns:
        The response text or any set of values that can be turned into a
        Response object using
        `make_response <http://flask.pocoo.org/docs/1.0/api/#flask.Flask.make_response>`.
    """
    from datetime import datetime, timedelta
    import pandas as pd
    import requests as r
    import json

    request_json = request.get_json()
    if request.args and 'message' in request.args:
        return request.args.get('message')
    elif request_json and 'message' in request_json:
        return request_json['message']
    else:
        today = datetime.today()
        yesterday = today - timedelta(days=1)
        today_format = today.strftime("%Y-%m-%d")
        yesterday_format = yesterday.strftime("%m-%d-%Y")

        data = api()

        bucket = "kaj_crypto"
       
        file_name = "crypto_" + yesterday_format + ".csv"
       
        upload_blob(data, bucket, file_name)
        
        return f"Written {url} to {bucket}/{name}"
