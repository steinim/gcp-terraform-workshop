output instance_address {
  value       = "${google_sql_database_instance.master.ip_address.0.ip_address}"
}
