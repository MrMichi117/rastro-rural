package co.edu.travesias.rastro;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.util.Map;

public final class Json {
    public static final ObjectMapper MAPPER = new ObjectMapper();
    public static JsonNode read(HttpServletRequest request) throws IOException {
        if (request.getContentType() == null || !request.getContentType().toLowerCase().startsWith("application/json"))
            throw new ApiException(415, "Se requiere application/json.");
        byte[] bytes = request.getInputStream().readNBytes(4_200_001);
        if (bytes.length > 4_200_000) throw new ApiException(413, "La solicitud es demasiado grande.");
        try {
            JsonNode node = MAPPER.readTree(bytes);
            if (node == null || !node.isObject()) throw new ApiException(422, "Se requiere un objeto JSON.");
            return node;
        } catch (com.fasterxml.jackson.core.JsonProcessingException e) {
            throw new ApiException(400, "JSON no válido.");
        }
    }
    public static void send(HttpServletResponse response, int status, Object body) throws IOException {
        byte[] bytes = MAPPER.writeValueAsBytes(body);
        response.setStatus(status);
        response.setContentType("application/json;charset=UTF-8");
        response.getOutputStream().write(bytes);
    }
    public static void error(HttpServletResponse response, int status, String message) throws IOException {
        send(response, status, Map.of("error", message));
    }
}
