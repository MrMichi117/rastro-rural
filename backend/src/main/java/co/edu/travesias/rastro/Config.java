package co.edu.travesias.rastro;

public final class Config {
    private Config() {}
    public static String get(String key, String fallback) {
        return System.getProperty(key, System.getenv().getOrDefault(key, fallback));
    }
    public static String required(String key) {
        String value = get(key, "");
        if (value.isBlank()) throw new IllegalStateException("Falta configurar " + key);
        return value;
    }
}
