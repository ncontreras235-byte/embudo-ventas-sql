-- ============================================================
-- PROYECTO: Análisis de Embudo de Ventas E-commerce
-- Autor: [Tu nombre]
-- Base de datos: BigQuery (Google SQL)
-- Dataset: embudo_ventas.embudo (9,381 registros)
-- Descripción: Análisis completo del embudo de conversión,
--              tasas por etapa, canales de tráfico e ingresos
-- ============================================================


-- ============================================================
-- 1. EXPLORACIÓN INICIAL
-- ============================================================

-- Vista previa de los datos
SELECT * FROM `practicasql-489521.embudo_ventas.embudo` LIMIT 10;

-- Conocer las etapas del embudo de ventas
SELECT DISTINCT event_type 
FROM `practicasql-489521.embudo_ventas.embudo`;


-- ============================================================
-- 2. EMBUDO DE CONVERSIÓN (últimos 30 días)
-- ============================================================

-- Cantidad de usuarios únicos por etapa del embudo
WITH etapas_embudo AS (
    SELECT
        COUNT(DISTINCT CASE WHEN event_type = 'page_view' THEN user_id END) AS etapa_1_vista,
        COUNT(DISTINCT CASE WHEN event_type = 'add_to_cart' THEN user_id END) AS etapa_2_carrito,
        COUNT(DISTINCT CASE WHEN event_type = 'checkout_start' THEN user_id END) AS etapa_3_checkout,
        COUNT(DISTINCT CASE WHEN event_type = 'payment_info' THEN user_id END) AS etapa_4_pago,
        COUNT(DISTINCT CASE WHEN event_type = 'purchase' THEN user_id END) AS etapa_5_compra
    FROM `practicasql-489521.embudo_ventas.embudo`
    WHERE event_date >= TIMESTAMP_SUB((SELECT MAX(event_date) FROM `practicasql-489521.embudo_ventas.embudo`), INTERVAL 30 DAY)
)
SELECT * FROM etapas_embudo;


-- ============================================================
-- 3. TASAS DE CONVERSIÓN POR ETAPA
-- ============================================================

-- Porcentaje de usuarios que avanzan entre cada etapa
WITH etapas_embudo AS (
    SELECT
        COUNT(DISTINCT CASE WHEN event_type = 'page_view' THEN user_id END) AS etapa_1_vista,
        COUNT(DISTINCT CASE WHEN event_type = 'add_to_cart' THEN user_id END) AS etapa_2_carrito,
        COUNT(DISTINCT CASE WHEN event_type = 'checkout_start' THEN user_id END) AS etapa_3_checkout,
        COUNT(DISTINCT CASE WHEN event_type = 'payment_info' THEN user_id END) AS etapa_4_pago,
        COUNT(DISTINCT CASE WHEN event_type = 'purchase' THEN user_id END) AS etapa_5_compra
    FROM `practicasql-489521.embudo_ventas.embudo`
    WHERE event_date >= TIMESTAMP_SUB((SELECT MAX(event_date) FROM `practicasql-489521.embudo_ventas.embudo`), INTERVAL 30 DAY)
)
SELECT
    ROUND(etapa_2_carrito / etapa_1_vista * 100, 2) AS tasa_vista_a_carrito,
    ROUND(etapa_3_checkout / etapa_2_carrito * 100, 2) AS tasa_carrito_a_checkout,
    ROUND(etapa_4_pago / etapa_3_checkout * 100, 2) AS tasa_checkout_a_pago,
    ROUND(etapa_5_compra / etapa_4_pago * 100, 2) AS tasa_pago_a_compra,
    ROUND(etapa_5_compra / etapa_1_vista * 100, 2) AS tasa_vista_a_compra
FROM etapas_embudo;


-- ============================================================
-- 4. ANÁLISIS POR CANAL DE TRÁFICO
-- ============================================================

-- Rendimiento del embudo segmentado por fuente de tráfico
WITH embudo_por_origen AS (
    SELECT 
        traffic_source,
        COUNT(DISTINCT CASE WHEN event_type = 'page_view' THEN user_id END) AS vista,
        COUNT(DISTINCT CASE WHEN event_type = 'add_to_cart' THEN user_id END) AS carrito,
        COUNT(DISTINCT CASE WHEN event_type = 'checkout_start' THEN user_id END) AS checkout,
        COUNT(DISTINCT CASE WHEN event_type = 'payment_info' THEN user_id END) AS pago,
        COUNT(DISTINCT CASE WHEN event_type = 'purchase' THEN user_id END) AS compra
    FROM `practicasql-489521.embudo_ventas.embudo`
    WHERE event_date >= TIMESTAMP_SUB((SELECT MAX(event_date) FROM `practicasql-489521.embudo_ventas.embudo`), INTERVAL 30 DAY)
    GROUP BY traffic_source
)
SELECT *,
    ROUND(carrito / vista * 100, 2) AS tasa_vista_a_carrito,
    ROUND(compra / vista * 100, 2) AS tasa_vista_a_compra
FROM embudo_por_origen
ORDER BY tasa_vista_a_compra DESC;


-- ============================================================
-- 5. ANÁLISIS DE INGRESOS
-- ============================================================

-- Métricas de ingresos y valor promedio por usuario y orden
WITH ingresos_embudo AS (
    SELECT
        COUNT(DISTINCT CASE WHEN event_type = 'page_view' THEN user_id END) AS total_visitantes,
        COUNT(DISTINCT CASE WHEN event_type = 'purchase' THEN user_id END) AS total_compradores,
        COUNT(CASE WHEN event_type = 'purchase' THEN 1 END) AS total_ordenes,
        ROUND(SUM(CASE WHEN event_type = 'purchase' THEN amount END)) AS ingresos
    FROM `practicasql-489521.embudo_ventas.embudo`
    WHERE event_date >= TIMESTAMP_SUB((SELECT MAX(event_date) FROM `practicasql-489521.embudo_ventas.embudo`), INTERVAL 30 DAY)
)
SELECT *,
    ROUND(ingresos / total_visitantes, 2) AS ingreso_por_visitante,
    ROUND(ingresos / total_compradores, 2) AS ingreso_por_comprador,
    ROUND(ingresos / total_ordenes, 2) AS promedio_ingreso_orden
FROM ingresos_embudo;
