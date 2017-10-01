output "db_name" {
  value = "${google_sql_database.db.name}"
}

output "username" {
  value = "${google_sql_user.db_user.name}"
}

output "password" {
  value = "${random_id.password.b64}"
}

output "ip" {
  value = "${google_sql_database_instance.master.ip_address.0.ip_address}"
}
