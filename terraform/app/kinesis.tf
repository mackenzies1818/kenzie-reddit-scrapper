#resource "aws_kms_key" "kinesis_key" {
#  description = "KMS key for Kinesis stream encryption"
#}
#
#resource "aws_kinesis_stream" "kenzie" {
#  name             = var.kinesis_stream_name
#  shard_count      = 1
#  retention_period = 24
#
#  encryption_type = "KMS"
#  kms_key_id = aws_kms_key.kinesis_key.id
#}
#
#resource "aws_kinesis_stream_consumer" "kenzie_consumer" {
#  stream_arn = aws_kinesis_stream.kenzie.arn
#  name       = var.kinesis_stream_consumer_name
#}
