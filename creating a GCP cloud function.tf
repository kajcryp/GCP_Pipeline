exports.helloWorld = (req, res)  {
  let message = req.query.message || req.body.message || 'Hello World!';
  res.status(200).send(message);
}; 
//======== MAIN.TF FILE 
provider "google" {
  project = "noted-hangout-293809"
  region  = "us-central1"
  zone    = "us-central1-c"
  credentials = "noted-hangout-293809-fcb581e85dc6.json" // The credentials are the same as what we got from the service account
}

// This resource is creating a google storage bucket to which your csv files are dropped in
// Name of the bucket here is called "terraform-gcp-verylazycoder"

resource "google_storage_bucket" "bucket" {
  name = "kaj_crypto"
}

// Inside the bucket created, we add an object called index.zip and this should go into the function.zip file. This is the code that's created to bring the data through e.g JavaScript, Python etc
// In this case the function.zip file created in the youtube vid was a JavaScript function
resource "google_storage_bucket_object" "archive" {
  name   = "index.zip"
  bucket = google_storage_bucket.bucket.name
  source = "function.zip"  // in this index.zip it should contain the source code
}

// This is the main cloud function resource which should contain the name, the description and the run time. 
resource "google_cloudfunctions_function" "function" {
  name        = "function-get-crypto-data"
  description = "My function"
  runtime     = "python 3.9"

  available_memory_mb   = 128
  source_archive_bucket = google_storage_bucket.bucket.name
  source_archive_object = google_storage_bucket_object.archive.name
  trigger_http          = true
  timeout               = 60
  entry_point           = "Download_data"  // This is where the cloud function executes. For example with the covid data transfer project, the entry point is download_data
  labels = {
    my-label = "my-label-value"
  }

  environment_variables = {
    MY_ENV_VAR = "my-env-var-value"
  }
}

// After you created the function you need to give IAM permissions to that particular function so that only appropriate people can access that particular function
# IAM entry for a single user to invoke the function
resource "google_cloudfunctions_function_iam_member" "invoker" {
 cloud_function = google_cloudfunctions_function.function.name

  role   = "roles/cloudfunctions.invoker"
  member = "allUsers" // This means that anyone can invoke this particular function
}

resource "google_cloud_scheduler_job" "hellow-world-job" {
  name         = "terraform-tutorial"
  description  = "Hello World every 2minutes"
  schedule     = "0/2 * * * *"
  http_target {
    http_method = "GET"
    uri = google_cloudfunctions_function.function.https_trigger_url
    oidc_token {
      service_account_email = "<terraform-sa-email>"
    }
