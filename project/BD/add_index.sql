-- Для быстрой связи умершего с его могилой создадим индекс:
CREATE INDEX idx_deceased_grave_id ON deceased(grave_id);

--Чтобы быстро находить могилы (ускорим поиск местоположения могил)
CREATE INDEX idx_graves_plot_id ON graves(plot_id);

-- Для отчетности, какие заказы связаны с услугами
CREATE INDEX idx_orders_service_id ON orders(service_id);

-- Для быстрого поиска какой запрос связан с какой могилой
CREATE INDEX idx_orders_grave_id ON orders(grave_id);
