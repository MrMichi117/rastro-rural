package co.edu.travesias.rastro;

import jakarta.servlet.*;
import jakarta.servlet.http.*;
import java.io.IOException;

public final class SecurityFilter implements Filter {
    private Identity identity;
    @Override public void init(FilterConfig config) { identity = new Identity(); }
    @Override public void doFilter(ServletRequest incoming, ServletResponse outgoing, FilterChain chain) throws IOException, ServletException {
        HttpServletRequest req = (HttpServletRequest) incoming;
        HttpServletResponse res = (HttpServletResponse) outgoing;
        req.setCharacterEncoding("UTF-8");
        res.setHeader("Cache-Control", "no-store, max-age=0");
        res.setHeader("Pragma", "no-cache");
        res.setHeader("X-Content-Type-Options", "nosniff");
        res.setHeader("Referrer-Policy", "same-origin");
        res.setHeader("Content-Security-Policy", "default-src 'self'; script-src 'self' 'wasm-unsafe-eval'; style-src 'self' 'unsafe-inline'; img-src 'self' data: blob:; font-src 'self'; connect-src 'self'; worker-src 'self' blob:; object-src 'none'; base-uri 'self'; frame-ancestors 'self'; form-action 'self'");
        String path = req.getRequestURI().substring(req.getContextPath().length());
        try {
            if (path.startsWith("/api/")) {
                String header = req.getHeader("Authorization");
                boolean protectedRoute = !req.getMethod().equals("GET") || path.equals("/api/me") || "true".equals(req.getParameter("mine"));
                if (header != null || protectedRoute) {
                    var principal = identity.authenticate(header);
                    req.setAttribute("identity", principal);
                }
            }
            chain.doFilter(req, res);
        } catch (ApiException e) { Json.error(res, e.status, e.getMessage()); }
    }
}
