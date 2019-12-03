provider "google" {
  credentials = "${file("${var.credentials}")}"
  project     = "${var.gcp_project}"
  region      = "${var.region}"
}
resource "google_compute_network" "vpc_network" {
  name                    = "terraform-network"
  auto_create_subnetworks = "true"
}
resource "google_compute_instance" "instance1" {
  name         = "${var.instance_name}"
  machine_type = "n1-standard-1"
  zone = "${var.zone}"
tags = ["http-server", "https-server"]

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-9"
    }
  }

  network_interface {
    network       = "${google_compute_network.vpc_network.self_link}"
    access_config {
    }
  }
 metadata_startup_script = "sudo apt-get update -y; sudo apt-get install nginx -y; sudo -i; cd /etc/nginx/sites-enabled; sed -i 's/80/8080/g' default ; service nginx restart; adduser joe"
}
resource "google_compute_address" "instance1" {
    name = "instance1-address"
}
resource "google_compute_target_pool" "instance1" {
  name = "${var.target-pool}"
  instances = "${google_compute_instance.instance1.*.self_link}"
  health_checks = ["${google_compute_http_health_check.instance1.name}"]
}
resource "google_compute_forwarding_rule" "https-instance1" {
  name = "instance1-www-https-forwarding-rule"
  target = "${google_compute_target_pool.instance1.self_link}"
  ip_address = "${google_compute_address.instance1.address}"
  port_range = "8080"
}
resource "google_compute_http_health_check" "instance1" {
  name = "${var.health-check}"
  request_path = "/"
  port = 8080
  check_interval_sec = 1
  healthy_threshold = 1
  unhealthy_threshold = 10
  timeout_sec = 1
}
resource "google_compute_firewall" "firewall-internal" {
  name    = "instance1-firewall-internal"
  network = "${google_compute_network.vpc_network.name}"
  allow {
    protocol = "all"
  }
  source_ranges = ["10.0.0.0/20"]
}
resource "google_compute_firewall" "firewall-external" {
  name    = "instance1-firewall-external"
  network = "${google_compute_network.vpc_network.name}"
  allow {
      protocol = "tcp"
      ports = ["22", "80", "443", "8080", "8000"]
  }
  source_ranges = ["0.0.0.0/0"]
}
