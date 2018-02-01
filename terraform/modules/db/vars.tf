variable project { default = "" }

variable region { default = "europe-west1" }

variable database_version { default = "MYSQL_5_6" }

variable tier { default = "db-f1-micro" }

variable db_name { default = "default" }

variable db_charset { default = "" }

variable db_collation { default = "" }

variable user_name { default = "default" }

variable user_host { default = "%" }

variable user_password { default = "" }

variable activation_policy { default = "ALWAYS" }

variable disk_autoresize { default = false }

variable disk_size { default = 10 }

variable disk_type { default = "PD_SSD" }

variable pricing_plan { default = "PER_USE" }

variable replication_type { default = "SYNCHRONOUS" }

variable backup_configuration {
  type    = "map"
  default = {}
}

variable location_preference {
  type    = "list"
  default = []
}

variable maintenance_window {
  type    = "list"
  default = []
}

variable replica_configuration {
  type    = "list"
  default = []
}
