package no.bekk.db;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;

public class DbAccess {
	private Connection connect = null;
	private Statement statement = null;
	private ResultSet resultSet = null;
	private String user = null;
	private String password = null;
	private String dbName = null;
    private String dbIp = null;
    private String dbUrl = null;


	public DbAccess() {
    user = System.getProperty("db.user");
		password = System.getProperty("db.password");
		dbIp = System.getProperty("db.ip");
		dbName = System.getProperty("db.name");
		dbUrl = String.format("jdbc:mysql://%s:3306/%s", dbIp, dbName);
		try {
			connect = DriverManager.getConnection(dbUrl, user, password);
			System.out.println("Database connected!");
		} catch (SQLException e) {
			e.printStackTrace();
		}
	}

	public String sayNow() throws Exception {
		try {
			statement = connect.createStatement();
			resultSet = statement.executeQuery("SELECT NOW()");
			String message = null;
			while (resultSet.next()) {
				message = resultSet.getString(1);
			}
			return message + " :)";
		} catch (Exception e) {
                        e.printStackTrace();
			return "nothing :(";
		} finally {
			close();
		}

	}

	private void close() {
		try {
			if (resultSet != null) {
				resultSet.close();
			}

			if (statement != null) {
				statement.close();
			}

			if (connect != null) {
				connect.close();
			}
		} catch (Exception e) {

		}
	}

}
