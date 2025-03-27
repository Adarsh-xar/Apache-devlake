# Provider Configuration
terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 4.80.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}

# Variables
variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "region" {
  description = "GCP Region"
  default     = "us-central1"
  type        = string
}

variable "zone" {
  description = "GCP Zone"
  default     = "us-central1-a"
  type        = string
}

# Network Configuration
resource "google_compute_network" "devlake_network" {
  name                    = "devlake-network"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "devlake_subnet" {
  name          = "devlake-subnet"
  ip_cidr_range = "10.0.1.0/24"
  region        = var.region
  network       = google_compute_network.devlake_network.id
}

# Firewall Rules
resource "google_compute_firewall" "devlake_allow_ssh" {
  name    = "devlake-allow-ssh"
  network = google_compute_network.devlake_network.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["devlake"]
}

resource "google_compute_firewall" "devlake_allow_web" {
  name    = "devlake-allow-web"
  network = google_compute_network.devlake_network.name

  allow {
    protocol = "tcp"
    ports    = ["8080"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["devlake"]
}

# Compute Instance
resource "google_compute_instance" "devlake_vm" {
  name         = "devlake-instance"
  machine_type = "e2-medium"
  zone         = var.zone

  tags = ["devlake"]

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
      size  = 50
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.devlake_subnet.name

    access_config {
      # Ephemeral IP
    }
  }

  # Startup script to install Docker and DevLake
  metadata_startup_script = <<-EOF
    #!/bin/bash
    # Update system
    apt-get update && apt-get upgrade -y

    # Install Docker
    apt-get install -y docker.io docker-compose git curl
    usermod -aG docker $USER

    # Clone DevLake
    git clone https://github.com/apache/incubator-devlake.git /opt/devlake
    cd /opt/devlake

    # Prepare DevLake configuration
    cp .env.example .env

    # Start DevLake
    docker-compose up -d
  EOF

  # Service Account for VM
  service_account {
    scopes = ["cloud-platform"]
  }
}

# Output the VM's public IP
output "devlake_public_ip" {
  value = google_compute_instance.devlake_vm.network_interface[0].access_config[0].nat_ip
}