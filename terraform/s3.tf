resource "aws_s3_bucket" "pipeline_spike_orphan_bucket" {
  bucket = "pipeline-spike-orphan-bucket"
  acl    = "private"

  tags {
    Name        = "pipeline_spike_orphan_bucket"
    Environment = "Dev" 
  }
}

resource "aws_s3_bucket" "pipeline_spike_valid_bucket" {
  bucket = "pipeline-spike-valid-bucket"
  acl    = "private"

  tags {
    Name        = "pipeline_spike_valid_bucket"
    Environment = "Dev" 
  }
}

resource "aws_s3_bucket" "pipeline_spike_error_bucket" {
  bucket = "pipeline-spike-error-bucket"
  acl    = "private"

  tags {
    Name        = "pipeline_spike_error_bucket"
    Environment = "Dev" 
  }
}

