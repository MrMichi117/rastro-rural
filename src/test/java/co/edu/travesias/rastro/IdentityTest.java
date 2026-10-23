package co.edu.travesias.rastro;

import com.auth0.jwt.JWT;
import com.auth0.jwt.algorithms.Algorithm;
import org.junit.jupiter.api.Test;
import java.nio.file.Files;
import java.security.*;
import java.security.interfaces.*;
import java.time.Instant;
import java.util.Base64;
import static org.junit.jupiter.api.Assertions.*;

class IdentityTest {
    @Test void productionVerifiesSignatureIssuerAudienceAndExpiry() throws Exception {
        var generator=KeyPairGenerator.getInstance("RSA");generator.initialize(2048);var pair=generator.generateKeyPair();
        var file=Files.createTempFile("rastro-public-",".pem");
        Files.writeString(file,"-----BEGIN PUBLIC KEY-----\n"+Base64.getEncoder().encodeToString(pair.getPublic().getEncoded())+"\n-----END PUBLIC KEY-----");
        System.setProperty("APP_ENV","production");System.setProperty("JWT_PUBLIC_KEY_FILE",file.toString());System.setProperty("JWT_ISSUER","https://identity.example.test");
        try {
            var identity=new Identity();var algorithm=Algorithm.RSA256((RSAPublicKey)pair.getPublic(),(RSAPrivateKey)pair.getPrivate());
            String valid=JWT.create().withIssuer("https://identity.example.test").withAudience("rastro-rural").withSubject("id-externo").withClaim("preferred_username","mauro").withClaim("name","Mauro Pérez").withExpiresAt(Instant.now().plusSeconds(60)).sign(algorithm);
            assertEquals("id-externo",identity.verify("Bearer "+valid));
            assertEquals("mauro",identity.authenticate("Bearer "+valid).username());
            assertEquals("Mauro Pérez",identity.authenticate("Bearer "+valid).displayName());
            var otherPair=generator.generateKeyPair();
            String forged=JWT.create().withIssuer("https://identity.example.test").withAudience("rastro-rural").withSubject("id-externo").withExpiresAt(Instant.now().plusSeconds(60)).sign(Algorithm.RSA256((RSAPublicKey)otherPair.getPublic(),(RSAPrivateKey)otherPair.getPrivate()));
            assertThrows(ApiException.class,()->identity.verify("Bearer "+forged));
            assertThrows(ApiException.class,()->identity.verify("Bearer dev-vecino-1"));
            for(String issuer:new String[]{"https://identity.example.test","https://evil.test"}) {
                String expired=JWT.create().withIssuer(issuer).withAudience("rastro-rural").withSubject("id-externo").withExpiresAt(Instant.now().minusSeconds(60)).sign(algorithm);
                assertThrows(ApiException.class,()->identity.verify("Bearer "+expired));
            }
            String wrongAudience=JWT.create().withIssuer("https://identity.example.test").withAudience("otro").withSubject("id-externo").withExpiresAt(Instant.now().plusSeconds(60)).sign(algorithm);
            assertThrows(ApiException.class,()->identity.verify("Bearer "+wrongAudience));
            String missingExpiry=JWT.create().withIssuer("https://identity.example.test").withAudience("rastro-rural").withSubject("id-externo").sign(algorithm);
            assertThrows(ApiException.class,()->identity.verify("Bearer "+missingExpiry));
        } finally {System.setProperty("APP_ENV","development");Files.deleteIfExists(file);System.clearProperty("JWT_PUBLIC_KEY_FILE");System.clearProperty("JWT_ISSUER");}
    }
}
