resource "aws_glue_catalog_database" "database" {
  name        = "nuclei_db"
  description = "Database for nuclei findings"
}

resource "aws_glue_catalog_table" "table" {
  name          = "findings_db"
  database_name = aws_glue_catalog_database.database.name
  table_type    = "EXTERNAL_TABLE"

  storage_descriptor {
    location = "s3://jwalker-nuclei-runner-artifacts/findings/"

    input_format = "org.apache.hadoop.mapred.TextInputFormat"
    output_format = "org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat"

    column {
      name = "extracted-results"
      type = "array<string>"
    }
    column {
      name = "host"
      type = "string"
    }
    column {
      name = "info"
      type = "struct<author:array<string>,classification:struct<cve-id:string,cwe-id:array<string>>,description:string,name:string,reference:array<string>,severity:string,tags:array<string>>"
    }
    column {
      name = "matched-at"
      type = "string"
    }
    column {
      name = "matched-line"
      type = "string"
    }
    column {
      name = "matcher-status"
      type = "boolean"
    }
    column {
      name = "template-id"
      type = "string"
    }
    column {
      name = "timestamp"
      type = "timestamp"
    }
    column {
      name = "type"
      type = "string"
    }
    column {
      name = "matcher-name"
      type = "string"
    }

    serde_info {
      serialization_library = "org.openx.data.jsonserde.JsonSerDe"
      parameters = {
        "serialization.format" = "1"
      }
    }
  }

  partition_keys {
    name = "dt"
    type = "string"
  }

  parameters = {
    "EXTERNAL" = "TRUE"
    "compressionType" = "none"
    "classification" = "json"
    "typeOfData" = "file"
    "projection.enabled" = "true"
    "projection.dt.type" = "date"
    "projection.dt.format" = "yyyy/MM/dd/HH"
    "projection.dt.interval" = "1"
    "projection.dt.interval.unit" = "HOURS"
    "projection.dt.range" = "NOW-1YEARS,NOW"
  }
}