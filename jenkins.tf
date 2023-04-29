provider "docker" {}

resource "docker_image" "jenkins" {
  name         = "jenkinsci/blueocean"
  keep_locally = false
}

resource "docker_network" "jenkins" {
  name = "jenkins"
}

resource "docker_container" "jenkins" {
  image = docker_image.jenkins.image_id
  name  = "myjenkins-blueocean"

  networks_advanced {
    name = docker_network.jenkins.name
  }

  ports {
    internal = 8080
    external = 8081
  }

  ports {
    internal = 50000
    external = 50000
  }

  env = [
    "DOCKER_CERT_PATH=/certs/client",
    "DOCKER_TLS_VERIFY=1",
  ]

  volumes {
    volume_name    = "jenkins_data"
    container_path = "/var/jenkins_home"
  }

  volumes {
    volume_name    = "jenkins-docker-certs"
    container_path = "/certs/client"
  }
}

