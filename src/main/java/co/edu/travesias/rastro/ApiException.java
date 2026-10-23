package co.edu.travesias.rastro;

public final class ApiException extends RuntimeException {
    final int status;
    public ApiException(int status, String message) { super(message); this.status = status; }
}
