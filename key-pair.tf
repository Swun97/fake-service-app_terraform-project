# Generate private key
resource "tls_private_key" "fake_service_app" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

# Key pair in AWS
resource "aws_key_pair" "fake_service_app" {
  key_name   = "fake-service-app-ssh-key"
  public_key = tls_private_key.fake_service_app.public_key_openssh
}

# Save private key locally
resource "local_file" "private_key" {
  content         = tls_private_key.fake_service_app.private_key_pem
  filename        = "fake-service-app.pem"
  file_permission = "0400"
}
