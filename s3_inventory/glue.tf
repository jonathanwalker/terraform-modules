resource "aws_glue_catalog_database" "database" {
  name        = "s3_inventory"
  description = "Database for storing S3 inventory reports"
}

resource "aws_glue_catalog_table" "table" {
  for_each = var.s3_inventory_configuration

  name = replace(each.value["bucket"], "-", "_")
  database_name = aws_glue_catalog_database.database.name
  table_type = "EXTERNAL_TABLE"

  storage_descriptor {
    location = "s3://${aws_s3_bucket.inventory_bucket.id}/${each.value["bucket"]}/${each.value["bucket"]}-inventory/hive"

    input_format  = "org.apache.hadoop.hive.ql.io.SymlinkTextInputFormat"
    output_format = "org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat"

    columns {
      name = "bucket"
      type = "string"
    }
    columns {
      name = "key"
      type = "string"
    }
    columns {
      name = "version_id"
      type = "string"
    }
    columns {
      name = "is_latest"
      type = "boolean"
    }
    columns {
      name = "is_delete_marker"
      type = "boolean"
    }
    columns {
      name = "size"
      type = "bigint"
    }
    columns {
      name = "last_modified_date"
      type = "bigint"
    }
    columns {
      name = "e_tag"
      type = "string"
    }
    columns {
      name = "storage_class"
      type = "string"
    }
    columns {
      name = "is_multipart_uploaded"
      type = "boolean"
    }
    columns {
      name = "replication_status"
      type = "string"
    }
    columns {
      name = "encryption_status"
      type = "string"
    }
    columns {
      name = "object_lock_retention_until_date"
      type = "bigint"
    }
    columns {
      name = "object_lock_mode"
      type = "string"
    }
    columns {
      name = "object_lock_legal_hold_status"
      type = "string"
    }
    columns {
      name = "intelligent_tiering_access_tier"
      type = "string"
    }
    columns {
      name = "bucket_key_status"
      type = "string"
    }
    columns {
      name = "checksum_algorithm"
      type = "string"
    }

    ser_de_info {
      name                  = "ParquetHiveSerDe"
      serialization_library = "org.apache.hadoop.hive.ql.io.parquet.serde.ParquetHiveSerDe"
      parameters = {
        "serialization.format" = "\t"
      }
    }
  }

  # Projection configuration
  parameters = {
    "EXTERNAL"                = "TRUE"
    "projection.enabled"      = "true"
    "projection.dt.type"      = "date"
    "projection.dt.format"    = "yyyy-MM-dd-HH-mm"
    "projection.dt.interval"  = "1"
    "projection.dt.range"     = "2022-01-01-00-00,NOW"

    "projection.dt.interval.unit" = "DAYS"
  }

  partition_keys {
    name = "dt"
    type = "string"
  }
}