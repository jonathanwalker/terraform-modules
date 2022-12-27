# Download nuclei binary
resource "null_resource" "download-nuclei" {
  triggers = {
    version = var.nuclei_version
  }

  provisioner "local-exec" {
    command = "curl -o ${path.module}/src/nuclei.zip -L https://github.com/projectdiscovery/nuclei/releases/download/v${var.nuclei_version}/nuclei_${var.nuclei_version}_${var.nuclei_arch}.zip"
  }
}

resource "aws_s3_upload" "upload" {
  bucket = aws_s3_bucket.bucket.id
  key    = "nuclei.zip"
  source = "${path.module}/src/nuclei.zip"
}

# Build lambda function
resource "null_resource" "build" {
  triggers = {
    always = timestamp()
  }

  provisioner "local-exec" {
    command = "cd ${path.module}/src && GOOS=linux GOARCH=amd64 CGO_ENABLED=0 go build -o main"
  }
}

# archive binary from build
data "archive_file" "zip" {
  depends_on  = [null_resource.build]
  type        = "zip"
  source_file = "src/main"
  output_path = "lambda.zip"
}