resource "random_id" "db_name" {
  prefix      = "${var.name}-master-db-"
  byte_length = 8
}

resource "google_sql_database_instance" "master" {
  name    = "${random_id.db_name.hex}"
  region  = "${var.region}"
  project = "${var.project}"
  settings {
    tier = "${var.tier}"
    ip_configuration {
      ipv4_enabled = "true"
      authorized_networks {
        name  = "all"
        value = "0.0.0.0/0"
      }
    }
  }
}

resource "google_sql_database" "db" {
  name      = "${var.name}-db"
  instance  = "${google_sql_database_instance.master.name}"
  charset   = "latin1"
  collation = "latin1_swedish_ci"
}

resource "random_id" "password" {
  byte_length = 32
}

resource "google_sql_user" "db_user" {
  name     = "${var.name}"
  instance = "${google_sql_database_instance.master.name}"
  host     = "${var.host}"
  password = "${random_id.password.b64}"
}
