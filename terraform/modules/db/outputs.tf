output instance_name {
  description = "The name of the database instance"
  value       = "${google_sql_database_instance.master.name}"
}

output instance_address {
  description = "The IPv4 address of the master database instance"
  value       = "${google_sql_database_instance.master.ip_address.0.ip_address}"
}

output instance_address_time_to_retire {
  description = "The time the master instance IP address will be retired. RFC 3339 format."
  value       = "${google_sql_database_instance.master.ip_address.0.time_to_retire}"
}

output self_link {
  description = "Self link to the master instance"
  value       = "${google_sql_database_instance.master.self_link}"
}

