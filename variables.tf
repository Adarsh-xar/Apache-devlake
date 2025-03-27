variable "project_id" {
    description = "The GCP project id"
    type = string
}

variable "region" {
    description = "The Region Of the project"
    type = string
    default = "asia-south2"
}

variable "machine_type" {
    description = "GCP Machine type would be described here"
    type = string
    default = "e2-micro"
}

variable "disk_size" {
    description = "Disk size in Gb"
    type = number
    default = 50
}