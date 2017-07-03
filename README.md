# ath

ath is a interactive [Amazon Athena](https://aws.amazon.com/athena/) shell.

[![asciicast](https://asciinema.org/a/127476.png)](https://asciinema.org/a/127476)

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'ath'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install ath

## Getting Started

```sh
$ export AWS_ACCESS_KEY_ID=...
$ export AWS_SECRET_ACCESS_KEY=...
$ export AWS_REGION=ap-northeast-1
$ export ATH_OUTPUT_LOCATION=s3://my-bucket
$ #export ATH_PAGER='column -t -s,'

$ ath

default> show databases;
default
sampledb

default> /use sampledb
sampledb> show tables;
elb_logs

sampledb> select * from elb_logs limit 3;
"request_timestamp","elb_name","request_ip","request_port","backend_ip","backend_port","request_processing_time","backend_processing_time","client_response_time","elb_response_code","backend_response_code","received_bytes","sent_bytes","request_verb","url","protocol","user_agent","ssl_cipher","ssl_protocol"
"2015-01-01T08:00:00.516940Z","elb_demo_009","240.136.98.149","25858","172.51.67.62","8888","9.99E-4","8.11E-4","0.001561","200","200","0","428","GET","https://www.example.com/articles/746","HTTP/1.1","""Mozilla/5.0 (Macintosh; Intel Mac OS X 10_11_6) AppleWebKit/602.1.50 (KHTML, like Gecko) Version/10.0 Safari/602.1.50""","DHE-RSA-AES128-SHA","TLSv1.2"
"2015-01-01T08:00:00.902953Z","elb_demo_008","244.46.184.108","27758","172.31.168.31","443","6.39E-4","0.001471","3.73E-4","200","200","0","4231","GET","https://www.example.com/jobs/688","HTTP/1.1","""Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:15.0) Gecko/20100101 Firefox/15.0.1""","DHE-RSA-AES128-SHA","TLSv1.2"
"2015-01-01T08:00:01.206255Z","elb_demo_008","240.120.203.212","26378","172.37.170.107","8888","0.001174","4.97E-4","4.89E-4","200","200","0","2075","GET","http://www.example.com/articles/290","HTTP/1.1","""Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/42.0.2311.135 Safari/537.36 Edge/12.246""","-","-"

sampledb> select * from elb_logs limit 3 &
QueryExecution 2335c77b-d138-4c5d-89df-12f2781c311b

sampledb> /desc 2335c77b-d138-4c5d-89df-12f2781c311b
{
  "query_execution_id": "2335c77b-d138-4c5d-89df-12f2781c311b",
  "query": "select * from elb_logs limit 3",
  "result_configuration": {
    "output_location": "s3://sugawara-test/2335c77b-d138-4c5d-89df-12f2781c311b.csv"
  },
  "query_execution_context": {
    "database": "sampledb"
  },
  "status": {
    "state": "SUCCEEDED",
    "submission_date_time": "2017-07-02 16:29:57 +0900",
    "completion_date_time": "2017-07-02 16:29:58 +0900"
  },
  "statistics": {
    "engine_execution_time_in_millis": 719,
    "data_scanned_in_bytes": 422696
  }
}

sampledb> /result 2335c77b-d138-4c5d-89df-12f2781c311b
"request_timestamp","elb_name","request_ip","request_port","backend_ip","backend_port","request_processing_time","backend_processing_time","client_response_time","elb_response_code","backend_response_code","received_bytes","sent_bytes","request_verb","url","protocol","user_agent","ssl_cipher","ssl_protocol"
"2015-01-01T16:00:00.516940Z","elb_demo_009","242.76.140.141","18201","172.42.159.57","80","0.001448","8.46E-4","9.97E-4","302","302","0","2911","GET","https://www.example.com/articles/817","HTTP/1.1","""Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:15.0) Gecko/20100101 Firefox/15.0.1""","DHE-RSA-AES128-SHA","TLSv1.2"
"2015-01-01T16:00:00.902953Z","elb_demo_005","246.233.91.115","1950","172.42.232.155","8888","9.59E-4","0.001703","8.93E-4","200","200","0","3027","GET","http://www.example.com/jobs/509","HTTP/1.1","""Mozilla/5.0 (Macintosh; Intel Mac OS X 10_11_6) AppleWebKit/602.1.50 (KHTML, like Gecko) Version/10.0 Safari/602.1.50""","-","-"
"2015-01-01T16:00:01.206255Z","elb_demo_002","250.96.73.238","12800","172.34.87.144","80","0.001549","9.68E-4","0.001908","200","200","0","888","GET","http://www.example.com/articles/729","HTTP/1.1","""Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/42.0.2311.135 Safari/537.36 Edge/12.246""","-","-"

sampledb> /pager column -t -s,

sampledb> select elb_name, count(*) from elb_logs group by elb_name;
"elb_name"      "_col1"
"elb_demo_006"  "151901"
"elb_demo_008"  "150503"
"elb_demo_007"  "149122"
"elb_demo_001"  "151753"
"elb_demo_005"  "149934"
"elb_demo_009"  "151886"
"elb_demo_004"  "151062"
"elb_demo_002"  "151284"
"elb_demo_003"  "148761"

sampledb> /list 1
2017-07-03 20:52:24 +0900 cf881630-a845-424a-8035-afe155505cac SUCCEEDED select elb_name   cou..

default> /save cf881630-a845-424a-8035-afe155505cac
Save to /Users/.../cf881630-a845-424a-8035-afe155505cac.csv
```

```sh
$ echo 'select count(*) from elb_logs' | ath -d sampledb -f -
"_col0"
"1356206"
```

## Usage

```
$ ath -h
Usage: ath [options]
    -p, --profile PROFILE_NAME
        --credentials-path PATH
    -k, --access-key ACCESS_KEY
    -s, --secret-key SECRET_KEY
    -r, --region REGION
        --output-location S3URI
    -d, --database DATABASE
    -e, --execute QUERY
    -f, --file QUERY_FILR
        --pager PAGER
        --[no-]progress
        --debug
```

```
default> /help
/debug true|false
/desc QUERY_EXECUTION_ID
/help
/list [NUM]
/output_location [S3URL]
/pager PAGER
/region [REGION]
/result QUERY_EXECUTION_ID
/save QUERY_EXECUTION_ID [PATH]
/stop QUERY_EXECUTION_ID
/use DATABASE
```
