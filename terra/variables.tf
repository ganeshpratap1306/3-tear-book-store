variable "region" {
  default = "ap-south-1"
}

variable "instance_type" {
  default = "t2.micro"
}

variable "ami" {
  description = "Ubuntu AMI"
  default     = "ami-0f5ee92e2d63afc18" # Update if needed
}

variable "key_name" {
  description = "SSH key pair"
  default     = "my-key"
}

variable "web_image" {
  description = "ECR/Docker image for web"
  default     = "your-dockerhub/web:latest"
}

variable "app_repo" {
  description = "Git repo for backend"
  default     = "https://github.com/yourrepo/app.git"
}