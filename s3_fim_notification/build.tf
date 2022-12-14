resource "null_resource" "build" {
  # trigger when src/main.go changes
  triggers = {
    main = filemd5("${path.module}/src/main.go")
  }

  provisioner "local-exec" {
    command = "cd ${path.module}/src && GOOS=linux GOARCH=amd64 CGO_ENABLED=0 go build -o main"
  }
}