package co.edu.travesias.rastro;

import com.zaxxer.hikari.HikariConfig;
import com.zaxxer.hikari.HikariDataSource;
import jakarta.servlet.ServletContextEvent;
import jakarta.servlet.ServletContextListener;
import java.sql.Connection;
import java.sql.SQLException;

public final class Database implements ServletContextListener {
    private static HikariDataSource pool;
    @Override public void contextInitialized(ServletContextEvent event) {
        HikariConfig config = new HikariConfig();
        config.setJdbcUrl(Config.required("DB_URL"));
        config.setUsername(Config.required("DB_USER"));
        config.setPassword(Config.required("DB_PASSWORD"));
        config.setMaximumPoolSize(10);
        config.setConnectionTimeout(5000);
        pool = new HikariDataSource(config);
    }
    public static Connection connection() throws SQLException { return pool.getConnection(); }
    @Override public void contextDestroyed(ServletContextEvent event) {
        if (pool != null) pool.close();
    }
}
