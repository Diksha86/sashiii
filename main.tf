provider "google" {
  credentials = "${file("${var.credentials}")}"
  project     = "${var.gcp_project}"
  region      = "${var.region}"
}
resource "google_project_iam_binding" "project" {
  project = "${var.gcp_project}"
  role    = "roles/compute.osLogin"

  members = [
    "user:shriyut.jha@cognizant.com",
  ]
}
resource "google_project_iam_binding" "project1" {
  project = "${var.gcp_project}"
  role    = "roles/iam.serviceAccountUser"

  members = [
    "user:shriyut.jha@cognizant.com",
  ]
}
resource "google_compute_instance_group" "staging_group" {
  name      = "staging-instance-group"
  zone      = "${var.zone}"
  instances = ["${google_compute_instance.instance1.self_link}"]
  network     = "${google_compute_network.vpc_network.self_link}"
  named_port {
    name = "http"
    port = "8080"
  }

  named_port {
    name = "https"
    port = "8443"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "google_compute_network" "vpc_network" {
  name                    = "terraform-network"
  auto_create_subnetworks = "false"
}

resource "google_compute_subnetwork" "public" {
 name          = "public"
 ip_cidr_range = "${var.vpc_public}"
 network       = "terraform-network"
 depends_on    = ["google_compute_network.vpc_network"]
 region        = "${var.region}"
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
    subnetwork = "${google_compute_subnetwork.public.name}"
    access_config {
    }
  }
  metadata = {
   enable-oslogin = "TRUE"
  }
 metadata_startup_script = "sudo apt-get update -y; sudo apt-get install nginx -y; sudo -i; cd /etc/nginx/sites-enabled; sed -i 's/80/8080/g' default ; service nginx restart"
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
resource "google_compute_firewall" "firewall-external" {
  name    = "instance1-firewall-external"
  network = "${google_compute_network.vpc_network.name}"
  allow {
      protocol = "tcp"
      ports = ["8080","22"]
  }
  direction = "INGRESS"
  source_ranges = ["0.0.0.0/0"]
}
