package co.edu.travesias.rastro;

import java.sql.Connection;
import java.sql.SQLException;
import java.util.Map;
import static co.edu.travesias.rastro.Repository.*;

/** Perfil local del login único. Recibe únicamente identidades verificadas por Identity. */
public final class LoginService {
    public Map<String,Object> load(Identity.Principal identity) throws SQLException {
        try (Connection c = Database.connection()) {
            c.setAutoCommit(false);
            try {
                // El upsert bloquea la referencia común y serializa accesos iniciales simultáneos.
                ensureUser(c, identity.id());
                var existing = query(c,"SELECT emisor FROM login WHERE usuario_id=? FOR UPDATE",identity.id());
                if (!existing.isEmpty() && !identity.issuer().equals(existing.get(0).get("emisor")))
                    throw new ApiException(401,"La cuenta pertenece a otra plataforma. Solicita ayuda al administrador.");
                if (existing.isEmpty()) {
                    update(c,"INSERT INTO login(usuario_id,emisor,nombre_usuario,nombre_visible) VALUES (?,?,?,?)",
                        identity.id(), identity.issuer(), identity.username(), identity.displayName());
                } else {
                    update(c,"UPDATE login SET nombre_usuario=?,nombre_visible=?,ultimo_acceso=CURRENT_TIMESTAMP WHERE usuario_id=?",
                        identity.username(), identity.displayName(), identity.id());
                }
                var profile = query(c,"SELECT usuario_id,nombre_usuario,nombre_visible,primer_acceso,ultimo_acceso FROM login WHERE usuario_id=?",identity.id()).get(0);
                c.commit();
                return profile;
            } catch (SQLException | RuntimeException e) { c.rollback(); throw e; }
        }
    }
}
