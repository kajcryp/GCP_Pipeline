
// Terraflow configuration to build a simple etherium streaming solution

// How to run:
// 1) Put below script in a VM/cloud console with an existing GCP project 
// 2) While in directory where this file is located, execute "terraform init" command to initiate terraform 
//    and download/update any resource packages required to run below code
// 3) If needed, change any of the variables/settings in below code to match naming conventions in your project
// 4) Execute "terraform plan" to check if the code compiles correctly
// 5) Execute "terraform deploy" to run and deploy the solution. 
//    If everything goes well, You should see a new bigquery dataset+"transactions" table within thereof, a cloud storage bucket,
//    a pubsub subscription and a dataflow job. Data should start streaming to the transactions table automatically
// 6) When you want to remove the Data Streaming PoC, simply execute "terraform destroy" to remove all components. 




// Creates BQ dataset
// Notes:
// Change or remove default_table_expiration_ms if you do not want the tables in the dataset to expire and get auto removed
terraform {
  required_providers {
  aws = ">= version"
  }
}



resource random_pet name {
  length    = length
  prefix    = ""
  separator = ""

  keepers = {
    id = value
  }
}


resource "google_bigquery_dataset" "default" {
  dataset_id                  = "crypto_terra_test"
  friendly_name               = "crypto_terra_test"
  description                 = "This is a test description"
  location                    = "EU"
  default_table_expiration_ms = 3600000
  labels = {
    env = "default"
  }
}



// Creates BQ Table within a specified dataset 
// Notes:
// deletion_protection=false allows for terraflow to remove the table using "Terraform destroy" command, remove if you want to preserve data!
// Schema can either be applied like one below or parsed via a file("path") format linking to a local file  

resource "google_bigquery_table" "default" {
  dataset_id = google_bigquery_dataset.default.dataset_id
  deletion_protection=false
  table_id   = "transactions"
  schema = "[     
					{   \"mode\": \"NULLABLE\",   \"name\": \"type\",   						          \"type\": \"STRING\"     	},
					{   \"mode\": \"NULLABLE\",   \"name\": \"hash\",   						          \"type\": \"STRING\"     	},
					{   \"mode\": \"NULLABLE\",   \"name\": \"nonce\",   						          \"type\": \"INTEGER\"     	},
					{   \"mode\": \"NULLABLE\",   \"name\": \"transaction_index\",   			    \"type\": \"INTEGER\"     	},
					{   \"mode\": \"NULLABLE\",   \"name\": \"from_address\",   				      \"type\": \"STRING\"     	},
					{   \"mode\": \"NULLABLE\",   \"name\": \"to_address\",   					      \"type\": \"STRING\"     	},
					{   \"mode\": \"NULLABLE\",   \"name\": \"value\",   						          \"type\": \"INTEGER\"     	},
					{   \"mode\": \"NULLABLE\",   \"name\": \"gas\",   							          \"type\": \"INTEGER\"     	},
					{   \"mode\": \"NULLABLE\",   \"name\": \"input\",   						          \"type\": \"STRING\"     	},
					{   \"mode\": \"NULLABLE\",   \"name\": \"block_timestamp\",   				    \"type\": \"INTEGER\"     	},
					{   \"mode\": \"NULLABLE\",   \"name\": \"block_number\",   				      \"type\": \"INTEGER\"     	},
					{   \"mode\": \"NULLABLE\",   \"name\": \"block_hash\",   					      \"type\": \"STRING\"     	},
					{   \"mode\": \"NULLABLE\",   \"name\": \"max_fee_per_gas\",   				    \"type\": \"INTEGER\"     	},
					{   \"mode\": \"NULLABLE\",   \"name\": \"max_priority_fee_per_gas\",     \"type\": \"INTEGER\"     	},
					{   \"mode\": \"NULLABLE\",   \"name\": \"transaction_type\",   			    \"type\": \"INTEGER\"     	},
					{   \"mode\": \"NULLABLE\",   \"name\": \"receipt_cumulative_gas_used\",  \"type\": \"INTEGER\"     	},
					{   \"mode\": \"NULLABLE\",   \"name\": \"receipt_gas_used\",   			    \"type\": \"INTEGER\"     	},
					{   \"mode\": \"NULLABLE\",   \"name\": \"receipt_contract_address\",   	\"type\": \"STRING\"     	},
					{   \"mode\": \"NULLABLE\",   \"name\": \"receipt_root\",   				      \"type\": \"STRING\"     	},
					{   \"mode\": \"NULLABLE\",   \"name\": \"receipt_status\",   				    \"type\": \"INTEGER\"     	},
					{   \"mode\": \"NULLABLE\",   \"name\": \"receipt_effective_gas_price\",  \"type\": \"INTEGER\"     	},
					{   \"mode\": \"NULLABLE\",   \"name\": \"item_id\",   						        \"type\": \"STRING\"     	},
					{   \"mode\": \"NULLABLE\",   \"name\": \"item_timestamp\",   				    \"type\": \"STRING\"     	},
					{   \"mode\": \"NULLABLE\",   \"name\": \"gas_price\",   					        \"type\": \"INTEGER\"     	}
					
				] "  

}



// Creates a Cloud Storage Bucket 
// Notes:
// This will be used as a temporary storage for the dataflow job 
// force_destroy allows for all data and bucket to be removed using "Terraform destroy" command, remove if you want to preserve data! 

resource "google_storage_bucket" "default" {
  name          = "dufrain_dev_crypto_data_terra_test"
  location      = "EU"
  force_destroy = true
}



// Creates a Pubsub Subscription
// Notes:
// project links to the target project that is storing the topic we want to subscribe to

resource "google_pubsub_subscription" "default" {
  name 		= "crypto_ethereum_terra_test.transactions.PoC"
  topic 	= "crypto_ethereum.transactions"
}



// Creates a Dataflow Job from a preset
// Notes:
// temp_gcs_location uses the GCS bucket created earlier in the script as a temporary drop location 
// template_gcs_path allows us to create basic jobs without having to write them from scratch

resource "google_dataflow_job" "pubsub_stream" {
    name = "transaction_streaming_terra_test"
    template_gcs_path = "gs://dataflow-templates-europe-west2/latest/PubSub_Subscription_to_BigQuery"
    temp_gcs_location = "gs://dufrain_dev_crypto_data_terra_test/"
    enable_streaming_engine = true
    on_delete = "cancel"
    machine_type ="g1-small"
    region = "europe-west2"
    max_workers = 1
    parameters = {
    inputSubscription="projects/dufrain-dev-data-streaming/subscriptions/crypto_ethereum_terra_test.transactions.PoC"
    outputTableSpec="dufrain-dev-data-streaming:crypto_data_terra_test.transactions"
    }
}

resource local_file name {
  sensitive_content = ""
  filename             = "${path.module}/files/outputfile"
  file_permission      = 0777
  directory_permission = 0777
}

resource random_uuid name {
  keepers = {
    id = value
  }
}

resource template_dir name {
  source_dir      = sourcepath
  destination_dir = destinationpath

  vars = {
    var = value
  }
}
