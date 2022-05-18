import argparse
import logging
import re
import csv
import os
from datetime import datetime, timedelta
import datetime 
import apache_beam as beam
from apache_beam.options.pipeline_options import PipelineOptions
from apache_beam.options.pipeline_options import SetupOptions, GoogleCloudOptions, SetupOptions

class CustomPipelineOptions(PipelineOptions):
    @classmethod
    #pass my input file into this particular function - aim of this function 
    def _add_argparse_args(cls, parser):
        parser.add_argument(
          '--input',
          help='Path of the file to read from')
        
def run(argv=None, save_main_session=True):
    os.environ['GOOGLE_APPLICATION_CREDENTIALS'] =  'service_account.json' #Get the service account details/key and save it to your cloud editor
    parser = argparse.ArgumentParser()
    known_args, pipeline_args = parser.parse_known_args(argv) 
    # don't find reference for known arguments but you do for pipeline_arguments
    #pipeline_args is the arguments file that you pass into the pipeline - base for creating a pipeline. 
    
    def parse_file(element):
        for line in csv.reader([element], quotechar='"', delimiter=',', quoting=csv.QUOTE_ALL, skipinitialspace=True):
            return line
    
    #This is the method that shows the pipeline options and is an object     
    #These are all the pipeline options you're combining together
    pipeline_options = PipelineOptions(
        pipeline_args,
        runner='DataflowRunner',
        project='kaj-crypto-project',
        job_name='cryptoPipeline',
        staging_location='gs://Crypto/BigQuery_Staging_Location',        
        temp_location='gs://Crypto_sandpit/Temp_BigQuery_Staging_Location',
        region='europe-west2')


    today = datetime.date.today()
    today_format = today.strftime("%Y-%m-%d")

    year = today.strftime("%Y")
    month = today.strftime("%m")
    
    file_location = "gs://kaj-crypto/{}/{}/crypto_data_".format(year, month)


    #once you run this, it creates a log file 
    pipeline_options.view_as(SetupOptions).save_main_session = save_main_session
    
    #schema to create for pipeline
    pipeline_schema = {
    'fields': [{
        'name': 'time_period_start', 	'type': 'TIMESTAMP', 		'mode': 'NULLABLE'
    }, {
        'name': 'time_period_end', 		'type': 'TIMESTAMP', 		'mode': 'REQUIRED'
    }, {
        'name': 'time_open', 			'type': 'TIMESTAMP', 		'mode': 'REQUIRED'
    }, {
        'name': 'time_close', 			'type': 'TIMESTAMP', 		'mode': 'REQUIRED'
    }, {
        'name': 'price_open', 			'type': 'FLOAT', 		    'mode': 'REQUIRED'
    }, {
        'name': 'price_high', 			'type': 'FLOAT', 		    'mode': 'REQUIRED'
    }, {
        'name': 'price_low', 			'type': 'FLOAT', 		    'mode': 'REQUIRED'
    }, {
        'name': 'price_close',      	'type': 'FLOAT', 		    'mode': 'REQUIRED'
    }, {
        'name': 'volume_traded',    	'type': 'FLOAT', 		    'mode': 'REQUIRED'
    }, {
        'name': 'trades_count', 		'type': 'INTEGER', 		    'mode': 'REQUIRED'
    }]
    }
    # The pipeline will be run on exiting the with block.
    p = beam.Pipeline(options=pipeline_options)
    (
        p

        | beam.io.ReadFromText(file_location + today_format + '.csv', skip_header_lines=1) # reads csv file
        
        | beam.Map(lambda x: parse_file(x)) 

        |'change the format to dict' >> beam.Map(lambda x: {
                'time_period_start': 	x[0],
                'time_period_end':	    x[1],
                'time_open':			x[2],
                'time_close':			x[3],
                'price_open':			x[4],
                'price_high':			x[5],
                'price_low':			x[6],
                'price_close':		    x[7],
                'volume_traded':		x[8],
                'trades_count':		    x[9]
            })
        | beam.io.WriteToBigQuery(
                                    'kaj-crypto:external_tables.dflow-crypto_activity',  
                                    schema = pipeline_schema,
                                    custom_gcs_temp_location='gs://kaj-crypto',
                                    write_disposition=beam.io.BigQueryDisposition.WRITE_APPEND,
                                    create_disposition=beam.io.BigQueryDisposition.CREATE_IF_NEEDED
                                 )
    )
    p.run().wait_until_finish()
    
if __name__ == '__main__':
    logging.getLogger().setLevel(logging.INFO)
    run()
