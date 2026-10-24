package co.edu.travesias.rastro;

import com.fasterxml.jackson.databind.JsonNode;
import java.time.*;
import java.util.Base64;
import java.io.ByteArrayInputStream;
import javax.imageio.ImageIO;

public final class Validation {
    public static final ZoneId ZONE = ZoneId.of("America/Bogota");
    public static String text(JsonNode n, String field, int max, boolean required) {
        JsonNode value = n.get(field);
        if (value != null && !value.isTextual() && !value.isNull()) throw invalid(field);
        String s = value == null || value.isNull() ? "" : value.asText().strip();
        if ((required && s.isBlank()) || s.length()>max || s.indexOf('\0')>=0) throw invalid(field);
        return s.isEmpty() ? null : s;
    }
    public static int integer(JsonNode n, String field, int min, int max) {
        JsonNode v=n.get(field);
        if(v==null || !v.isIntegralNumber() || !v.canConvertToInt() || v.intValue()<min || v.intValue()>max) throw invalid(field);
        return v.intValue();
    }
    public static LocalDate date(JsonNode n, String field) {
        try {
            LocalDate d=LocalDate.parse(text(n,field,10,true));
            if(d.isAfter(LocalDate.now(ZONE)) || d.isBefore(LocalDate.of(2000,1,1))) throw invalid(field);
            return d;
        } catch (DateTimeException e) { throw invalid(field); }
    }
    public static LocalDateTime dateTime(JsonNode n, String field) {
        try {
            LocalDateTime d=LocalDateTime.parse(text(n,field,30,true));
            if(d.isAfter(LocalDateTime.now(ZONE)) || d.getYear()<2000) throw invalid(field);
            return d;
        } catch (DateTimeException e) { throw invalid(field); }
    }
    public record Photo(byte[] bytes, String type) {}
    public static Photo photo(JsonNode n) {
        String data=text(n,"foto",4_000_000,false);
        if(data==null) return new Photo(null,null);
        try {
            String type=data.startsWith("data:image/jpeg;base64,") ? "image/jpeg" : data.startsWith("data:image/png;base64,") ? "image/png" : null;
            if(type==null) throw invalid("foto (solo JPEG o PNG)");
            byte[] bytes=Base64.getDecoder().decode(data.substring(data.indexOf(',')+1));
            if(bytes.length>2_000_000) throw invalid("foto (máximo 2 MB)");
            try(var input=ImageIO.createImageInputStream(new ByteArrayInputStream(bytes))) {
                var readers=ImageIO.getImageReaders(input);
                if(!readers.hasNext()) throw invalid("foto");
                var reader=readers.next();
                try {
                    reader.setInput(input);
                    String format=reader.getFormatName();
                    if(!(format.equalsIgnoreCase("JPEG") && type.equals("image/jpeg")) && !(format.equalsIgnoreCase("PNG") && type.equals("image/png"))) throw invalid("foto");
                    if((long)reader.getWidth(0)*reader.getHeight(0)>16_000_000) throw invalid("foto (máximo 16 megapíxeles)");
                    // Decodificar y recodificar elimina metadatos EXIF y contenido adjunto.
                    var decoded=reader.read(0);
                    var out=new java.io.ByteArrayOutputStream();
                    ImageIO.write(decoded,format,out);
                    if(out.size()>3_000_000) throw invalid("foto (reduce su resolución)");
                    return new Photo(out.toByteArray(),type);
                } finally { reader.dispose(); }
            }
        } catch(ApiException e) { throw e; } catch(Exception e) { throw invalid("foto"); }
    }
    public static ApiException invalid(String field) { return new ApiException(422,"Revisa el campo: " + field + "."); }
}
