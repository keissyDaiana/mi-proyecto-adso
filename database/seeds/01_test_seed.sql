-- ==============================================================================
-- SENA CADPH Garzón · Regional Huila · ADSO — Proyecto transversal
-- Sesión 06 · Semilla 01: datos de prueba (database/seeds/01_test_seed.sql)
-- ==============================================================================
-- SOLO DESARROLLO LOCAL. Ejecución:  psql -U postgres -d adso_auth_db -f database/seeds/01_test_seed.sql
-- ==============================================================================

-- -----------------------------------------------------------------------------
-- RETO 4: SIMULACIÓN TRANSACCIONAL DE REGISTRO CON EMISIÓN DE TOKEN
-- -----------------------------------------------------------------------------
-- ⚠️ Datos SOLO para desarrollo local. Estas cuentas y contraseñas son públicas
-- (están en GitHub): NUNCA se siembran en la base de datos de producción.
BEGIN;

-- 4.1 Administrador del sistema (ya verificado)
-- Hash bcrypt real (cost 12) de la contraseña de desarrollo: Admin2026*
INSERT INTO users (id, email, password_hash, role, is_verified)
VALUES (
    'a0000000-0000-0000-0000-000000000001',
    'admin@sena.edu.co',
    '$2a$12$XX4UDuvqTkT8BRWIc5bG/.f2Ijso/RPeN1DArncHoo1t9/8aaXP56',
    'admin',
    TRUE
);

-- 4.2 Aprendiz pendiente de verificación
-- Hash bcrypt real (cost 12) de la contraseña de desarrollo: Aprendiz2026*
INSERT INTO users (id, email, password_hash, role, is_verified)
VALUES (
    'b0000000-0000-0000-0000-000000000002',
    'aprendiz.adso@misena.edu.co',
    '$2a$12$Cbg/M9azmEzX26JhLT844uR95KrIjSBNMFAe9cN9n93gEca7K0Kma',
    'user',
    FALSE
);

-- 4.3 Token con expiración a 24 horas.
-- En la Sesión 11 el backend genera el token con crypto.randomBytes(32), lo envía
-- por correo y guarda solo su SHA-256. Aquí simulamos un token conocido
-- ('token-demo-sesion-06') para poder probar la verificación en la consulta 5.2.
INSERT INTO verification_tokens (user_id, token_hash, expires_at)
VALUES (
    'b0000000-0000-0000-0000-000000000002',
    encode(digest('token-demo-sesion-06', 'sha256'), 'hex'),
    NOW() + INTERVAL '24 hours'
);

COMMIT;

-- -----------------------------------------------------------------------------
-- RETO 5: CONSULTAS DE VALIDACIÓN Y CONTROL DE SEGURIDAD
-- -----------------------------------------------------------------------------

-- 5.1 Consulta analítica relacional: usuarios pendientes y horas restantes del token
SELECT
    u.id AS user_id,
    u.email,
    u.role,
    u.is_verified,
    t.expires_at,
    ROUND(EXTRACT(EPOCH FROM (t.expires_at - NOW())) / 3600, 2) AS hours_remaining
FROM users u
INNER JOIN verification_tokens t ON u.id = t.user_id
WHERE u.is_verified = FALSE;

-- 5.2 Vista previa del endpoint de activación (Sesión 13):
-- El usuario llega con el token ORIGINAL del enlace; se calcula su hash y se busca.
-- Solo es válido si existe y NO ha expirado.
SELECT
    u.id,
    u.email,
    u.is_verified
FROM verification_tokens t
INNER JOIN users u ON t.user_id = u.id
WHERE t.token_hash = encode(digest('token-demo-sesion-06', 'sha256'), 'hex')
  AND t.expires_at > NOW();
-- Resultado esperado: 1 fila (aprendiz.adso@misena.edu.co)

-- 5.3 Prueba del trigger updated_at:
-- UPDATE users SET role = 'user' WHERE email = 'admin@sena.edu.co';
-- SELECT email, created_at, updated_at FROM users;  -- updated_at > created_at

-- 5.4 Prueba de la restricción de minúsculas (debe FALLAR):
-- INSERT INTO users (email, password_hash) VALUES ('Admin@Sena.edu.co', 'x');
-- ERROR: new row for relation "users" violates check constraint "chk_users_email_lower"

-- 5.5 Demostración de Integridad Referencial (ON DELETE CASCADE):
-- DELETE FROM users WHERE id = 'b0000000-0000-0000-0000-000000000002';
-- SELECT COUNT(*) FROM verification_tokens WHERE user_id = 'b0000000-0000-0000-0000-000000000002';
-- (Resultado esperado: 0 filas)
