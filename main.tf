provider "google" {
  credentials = "${file(var.credentials)}"
  project     = "${var.project_id}"
  region      = "${var.region}"
}

resource "google_container_cluster" "cluster" {
  name               = "${var.name}"
  location           = "${var.region}"
  
  remove_default_node_pool = true
  initial_node_count = 1

  master_auth {
    username = ""
    password = ""
  }

  addons_config {
    network_policy_config {
      disabled = "false"
    }
  }

  network_policy {
    enabled = "true"
    provider = "CALICO"
  }


  node_config {
    machine_type = "${var.general_purpose_machine_type}"

    metadata = {
      disable-legacy-endpoints = "true"
    }

    # Needed for correctly functioning cluster, see 
    # https://www.terraform.io/docs/providers/google/r/container_cluster.html#oauth_scopes
    oauth_scopes = [
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
      "https://www.googleapis.com/auth/devstorage.read_only"
    ]
  }

}

resource "google_container_node_pool" "general_purpose" {
  name       = "${var.name}-general"
  location   = "${var.region}"
  cluster    = "${google_container_cluster.cluster.name}"

  management { 
    auto_repair = "true"
    auto_upgrade = "true"
  }

  autoscaling { 
    min_node_count = "${var.general_purpose_min_node_count}"
    max_node_count = "${var.general_purpose_max_node_count}"
  }
  initial_node_count = "${var.general_purpose_min_node_count}"

  node_config {
    machine_type = "${var.general_purpose_machine_type}"

    metadata = {
      disable-legacy-endpoints = "true"
    }

    # Needed for correctly functioning cluster, see 
    # https://www.terraform.io/docs/providers/google/r/container_cluster.html#oauth_scopes
    oauth_scopes = [
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
      "https://www.googleapis.com/auth/devstorage.read_only"
    ]
  }
}

resource "kubernetes_deployment" "nginx_deployment" {
  metadata {
    name = "deployment-terraform-starter"
    labels = {
      app = "nginx"
    }
  }
  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "nginx"
      }
    }

    template {
      metadata {
        labels = {
          app = "nginx"
        }
      }

      spec {
        container {
          image = "${var.docker_image}"
          name  = "app-nginx"
          
          port {
            container_port = 3000
          }

          resources {
            limits {
              cpu    = "0.5"
              memory = "512Mi"
            }
            requests {
              cpu    = "250m"
              memory = "50Mi"
            }
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "nginx" {
  metadata {
    name = "nginx-example"
  }
  spec {
    selector = {
      app = "${kubernetes_deployment.nginx_deployment.metadata[0].labels.app}"
    }
    port {
      port        = 80
      target_port = 3000
    }

    type = "LoadBalancer"
  }
}


# The following outputs allow authentication and connectivity to the GKE Cluster
# by using certificate-based authentication.
output "client_certificate" {
  value = "${google_container_cluster.cluster.master_auth.0.client_certificate}"
}

output "client_key" {
  value = "${google_container_cluster.cluster.master_auth.0.client_key}"
}

output "cluster_ca_certificate" {
  value = "${google_container_cluster.cluster.master_auth.0.cluster_ca_certificate}"
}
