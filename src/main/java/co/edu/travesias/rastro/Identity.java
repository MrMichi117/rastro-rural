package co.edu.travesias.rastro;

import com.auth0.jwt.JWT;
import com.auth0.jwt.JWTVerifier;
import com.auth0.jwt.algorithms.Algorithm;
import com.auth0.jwt.interfaces.DecodedJWT;
import java.nio.file.Files;
import java.nio.file.Path;
import java.security.KeyFactory;
import java.security.interfaces.RSAPublicKey;
import java.security.spec.X509EncodedKeySpec;
import java.util.Base64;

/** Adaptador de contrato propuesto. Nunca acepta usuario_id del formulario. */
public final class Identity {
    public record Principal(String id, String issuer, String username, String displayName) {}
    private final JWTVerifier verifier;
    private final boolean development;
    public Identity() {
        development = "development".equals(Config.get("APP_ENV", "production"));
        if (development) { verifier = null; return; }
        try {
            String pem = Files.readString(Path.of(Config.required("JWT_PUBLIC_KEY_FILE")))
                .replace("-----BEGIN PUBLIC KEY-----", "").replace("-----END PUBLIC KEY-----", "").replaceAll("\\s", "");
            RSAPublicKey key = (RSAPublicKey) KeyFactory.getInstance("RSA").generatePublic(new X509EncodedKeySpec(Base64.getDecoder().decode(pem)));
            verifier = JWT.require(Algorithm.RSA256(key, null)).withIssuer(Config.required("JWT_ISSUER"))
                .withAudience("rastro-rural").withClaimPresence("exp").build();
        } catch (Exception e) { throw new IllegalStateException("Configura la clave pública y el emisor de identidad.", e); }
    }
    public String verify(String bearer) { return authenticate(bearer).id(); }
    public Principal authenticate(String bearer) {
        if (bearer == null || !bearer.startsWith("Bearer ")) throw new ApiException(401, "Ingresa desde la plataforma comunitaria.");
        String token = bearer.substring(7);
        if (development && (token.equals("dev-vecino-1") || token.equals("dev-vecino-2")))
            return new Principal(token.substring(4), "urn:rastro:development", token.substring(4), token.endsWith("1") ? "Vecino 1" : "Vecino 2");
        if (verifier == null) throw new ApiException(401, "Identidad de desarrollo no válida.");
        try {
            DecodedJWT jwt = verifier.verify(token);
            String subject = jwt.getSubject();
            if (subject == null || subject.isBlank() || subject.length() > 128) throw new IllegalArgumentException();
            String issuer = jwt.getIssuer();
            if (issuer == null || issuer.length() > 255) throw new IllegalArgumentException();
            return new Principal(subject, issuer, profileText(jwt,"preferred_username",120), profileText(jwt,"name",160));
        } catch (Exception e) { throw new ApiException(401, "La identidad no es válida o venció. Vuelve a ingresar desde la plataforma."); }
    }
    private static String profileText(DecodedJWT jwt, String claim, int max) {
        if (jwt.getClaim(claim).isMissing() || jwt.getClaim(claim).isNull()) return null;
        String value = jwt.getClaim(claim).asString();
        if (value == null || value.length() > max || value.chars().anyMatch(Character::isISOControl)) throw new IllegalArgumentException();
        return value.isBlank() ? null : value.strip();
    }
}
