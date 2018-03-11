resource "aws_kinesis_stream" "pipeline_spike_stream" {
  name             = "pipeline_spike_stream"
  shard_count      = 1
  retention_period = 24
}
