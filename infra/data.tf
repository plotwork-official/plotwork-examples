# Parcels and their events live in Postgres; label PDFs in S3; carrier events arrive on a queue.
resource "aws_db_subnet_group" "tracking" {
  name       = "tracking"
  subnet_ids = [aws_subnet.private_a.id]
}

resource "aws_db_instance" "tracking" {
  identifier           = "tracking-db"
  engine               = "postgres"
  engine_version       = "16"
  instance_class       = "db.t4g.medium"
  allocated_storage    = 50
  db_subnet_group_name = aws_db_subnet_group.tracking.name
}

resource "aws_s3_bucket" "labels" {
  bucket = "parcelpoint-labels"
}

resource "aws_sqs_queue" "carrier_events" {
  name                       = "carrier-events"
  visibility_timeout_seconds = 60
}
