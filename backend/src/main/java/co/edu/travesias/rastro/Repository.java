package co.edu.travesias.rastro;

import java.sql.*;
import java.util.*;

/** Todas las entradas del cliente se enlazan como parámetros JDBC. */
public final class Repository {
    public static List<Map<String,Object>> query(Connection c, String sql, Object... values) throws SQLException {
        try (PreparedStatement st = c.prepareStatement(sql)) {
            bind(st, values);
            try (ResultSet rs = st.executeQuery()) {
                List<Map<String,Object>> rows = new ArrayList<>();
                while (rs.next()) {
                    Map<String,Object> row = new LinkedHashMap<>();
                    for (int i=1; i<=rs.getMetaData().getColumnCount(); i++) {
                        Object value = rs.getObject(i);
                        if (value instanceof java.sql.Date || value instanceof Timestamp || value instanceof java.time.temporal.TemporalAccessor) value = value.toString();
                        row.put(rs.getMetaData().getColumnLabel(i).toLowerCase(Locale.ROOT), value);
                    }
                    rows.add(row);
                }
                return rows;
            }
        }
    }
    public static int update(Connection c, String sql, Object... values) throws SQLException {
        try (PreparedStatement st = c.prepareStatement(sql)) { bind(st,values); return st.executeUpdate(); }
    }
    public static long insert(Connection c, String sql, Object... values) throws SQLException {
        try (PreparedStatement st = c.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
            bind(st,values); st.executeUpdate();
            try (ResultSet rs = st.getGeneratedKeys()) { if (rs.next()) return rs.getLong(1); throw new SQLException("No se generó ID"); }
        }
    }
    private static void bind(PreparedStatement st, Object[] values) throws SQLException {
        for (int i=0; i<values.length; i++) st.setObject(i+1,values[i]);
    }
}
